import Array "mo:base/Array";
import Candy "mo:candy/types";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import MigrationTypes "./migrations/types";
import Migrations "./migrations";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Types "./types";
import Utils "./utils";

shared deployer actor class EventSystem() = this {
  let StateTypes = MigrationTypes.Current;

  stable var migrationState: MigrationTypes.State = #state000(#data);

  migrationState := Migrations.migrate(migrationState, #state001(#id), { deployer = deployer.caller });

  let #state001(#data(state)) = migrationState;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  private func isAdmin(principalId: Principal): Bool {
    if (principalId == deployer.caller or principalId == Principal.fromActor(this)) return true;

    for (admin in state.admins.vals()) if (principalId == admin) return true;

    return false;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  private func updateEffectSubscribers() {
    for (event in state.events.vals()) event.subscribers := Array.filter(event.subscribers, func(subscriber: StateTypes.Subscriber): Bool {
      return Option.isSome(Array.find(subscriber.eventNames, func(eventName: Text): Bool { eventName == event.name }));
    });

    state.events := Array.filter(state.events, func(item: StateTypes.Event): Bool { item.subscribers.size() > 0 });
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  private func dispatchEvent(event: StateTypes.Event, subscriber: StateTypes.Subscriber): async () {
    if (not subscriber.stale) try {
      let subscriberActor: Types.SubscriberActor = actor(Principal.toText(subscriber.canisterId));

      let _ = await subscriberActor.handleEvent(event.canisterId, event.name, event.payload);

      event.subscribers := Array.filter(event.subscribers, func(item: StateTypes.Subscriber): Bool { item.canisterId != subscriber.canisterId });

      if (event.subscribers.size() == 0) state.events := Array.filter(state.events, func(item: StateTypes.Event): Bool { item.id != event.id });

      subscriber.firstFailedEventTime := 0;
    } catch (err) {
      let eventInfo = "(" # Nat.toText(event.id) # ", " # Principal.toText(event.canisterId) # ", " # event.name # ")";
      let subscriberInfo = "(" # Principal.toText(subscriber.canisterId) # ")";

      Debug.print("Error sending event " # eventInfo # " to " # subscriberInfo # ": " # Error.message(err));

      if (event.numberOfAttempts >= 11) event.stale := true;
      if (subscriber.firstFailedEventTime != 0 and Time.now() > subscriber.firstFailedEventTime + 604800000000000) subscriber.stale := true;
      if (subscriber.firstFailedEventTime == 0) subscriber.firstFailedEventTime := Time.now();
    };

    if (subscriber.stale and event.numberOfAttempts >= 11) event.stale := true;

    event.numberOfDispatches -= 1;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  private func processEvent(event: StateTypes.Event): async () {
    if (not event.stale and event.numberOfDispatches == 0 and event.nextProcessingTime > 0 and Time.now() >= event.nextProcessingTime) {
      event.numberOfAttempts += 1;
      event.nextProcessingTime := Time.now() + 400000000 * event.numberOfAttempts ** 5;

      for (subscriber in event.subscribers.vals()) {
        event.numberOfDispatches += 1;

        let _ = dispatchEvent(event, subscriber);
      };
    };
  };

  private func processEvents(): async () {
    for (event in state.events.vals()) {
      if (not event.stale and event.numberOfDispatches == 0 and event.nextProcessingTime > 0 and Time.now() >= event.nextProcessingTime) {
        let _ = processEvent(event);
      };
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared msg func addSubscription(canisterId: Principal, name: Text) {
    if (not isAdmin(msg.caller)) throw Error.reject("Not authorized");

    switch (Array.find(state.subscribers, func(item: StateTypes.Subscriber): Bool { item.canisterId == canisterId })) {
      case (?subscriber) {
        let hasEvent = Option.isSome(Array.find(subscriber.eventNames, func(eventName: Text): Bool { eventName == name }));

        if (not hasEvent) subscriber.eventNames := Array.append(subscriber.eventNames, [name]);
      };

      case (_) {
        let subscriber: StateTypes.Subscriber = {
          canisterId = canisterId;
          createdAt = Time.now();
          var firstFailedEventTime = 0;
          var stale = false;
          var eventNames = [name];
        };

        state.subscribers := Array.append(state.subscribers, [subscriber]);
      };
    };
  };

  public shared msg func subscribe(name: Text) {
    addSubscription(msg.caller, name);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared msg func removeSubscription(canisterId: Principal, name: Text) {
    if (not isAdmin(msg.caller)) throw Error.reject("Not authorized");

    switch (Array.find(state.subscribers, func(item: StateTypes.Subscriber): Bool { item.canisterId == canisterId })) {
      case (?subscriber) {
        let eventsSize = subscriber.eventNames.size();

        subscriber.eventNames := Array.filter(subscriber.eventNames, func(eventName: Text): Bool { eventName != name });

        if (eventsSize > subscriber.eventNames.size()) updateEffectSubscribers();

        if (subscriber.eventNames.size() == 0) {
          state.subscribers := Array.filter(state.subscribers, func(item: StateTypes.Subscriber): Bool { item.canisterId != subscriber.canisterId });
        };
      };

      case (_) {};
    };
  };

  public shared msg func unsubscribe(name: Text) {
    removeSubscription(msg.caller, name);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared msg func addEvent(canisterId: Principal, name: Text, payload: Candy.CandyValue) {
    if (not isAdmin(msg.caller)) throw Error.reject("Not authorized");

    let subscribers = Array.filter(state.subscribers, func(item: StateTypes.Subscriber): Bool {
      return Option.isSome(Array.find(item.eventNames, func(eventName: Text): Bool { eventName == name }));
    });

    if (subscribers.size() > 0) {
      let event: StateTypes.Event = {
        id = state.eventId;
        name = name;
        payload = payload;
        canisterId = canisterId;
        createdAt = Time.now();
        var nextProcessingTime = Time.now();
        var numberOfDispatches = 0;
        var numberOfAttempts = 0;
        var stale = false;
        var subscribers = subscribers;
      };

      state.eventId += 1;
      state.events := Array.append(state.events, [event]);

      let _ = processEvent(event);
    };
  };

  public shared msg func emit(name: Text, payload: Candy.CandyValue) {
    addEvent(msg.caller, name, payload);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared msg func fetchSubscribers(params: Types.FetchSubscribersParams): async Types.FetchSubscribersResponse {
    if (not isAdmin(msg.caller)) throw Error.reject("Not authorized");

    let canisterId = switch (params.filters) { case (?filters) Option.get(filters.canisterId, []); case (_) [] };
    let stale = switch (params.filters) { case (?filters) Option.get(filters.stale, []); case (_) [] };
    let eventNames = switch (params.filters) { case (?filters) Option.get(filters.eventNames, []); case (_) [] };

    let filteredSubscribers = Array.filter(state.subscribers, func(subscriber: StateTypes.Subscriber): Bool {
      if (canisterId.size() > 0 and Array.find(canisterId, func(item: Principal): Bool { item == subscriber.canisterId }) == null) return false;
      if (stale.size() > 0 and Array.find(stale, func(item: Bool): Bool { item == subscriber.stale }) == null) return false;

      if (eventNames.size() > 0) {
        let hasIntersectingNames = Option.isSome(Array.find(eventNames, func(item: Text): Bool { 
          return Option.isSome(Array.find(subscriber.eventNames, func(subscriberEvent: Text): Bool { item == subscriberEvent }));
        }));

        if (not hasIntersectingNames) return false;
      };

      return true;
    });

    let limitedSubscribers = Utils.arraySlice(filteredSubscribers, params.offset, ?(Option.get(params.offset, 0) + params.limit));

    let sharedSubscribers = Array.map(limitedSubscribers, func(subscriber: StateTypes.Subscriber): Types.SharedSubscriber {{
      canisterId = subscriber.canisterId;
      createdAt = subscriber.createdAt;
      firstFailedEventTime = subscriber.firstFailedEventTime;
      stale = subscriber.stale;
      eventNames = subscriber.eventNames;
    }});

    return { items = sharedSubscribers; totalCount = filteredSubscribers.size() };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared msg func fetchEvents(params: Types.FetchEventsParams): async Types.FetchEventsResponse {
    if (not isAdmin(msg.caller)) throw Error.reject("Not authorized");

    let id = switch (params.filters) { case (?filters) Option.get(filters.id, []); case (_) [] };
    let name = switch (params.filters) { case (?filters) Option.get(filters.name, []); case (_) [] };
    let canisterId = switch (params.filters) { case (?filters) Option.get(filters.canisterId, []); case (_) [] };
    let stale = switch (params.filters) { case (?filters) Option.get(filters.stale, []); case (_) [] };
    let attempts = switch (params.filters) { case (?filters) Option.get(filters.numberOfAttempts, []); case (_) [] };

    let filteredEvents = Array.filter(state.events, func(event: StateTypes.Event): Bool {
      if (id.size() > 0 and Array.find(id, func(item: Nat): Bool { item == event.id }) == null) return false;
      if (name.size() > 0 and Array.find(name, func(item: Text): Bool { item == event.name }) == null) return false;
      if (canisterId.size() > 0 and Array.find(canisterId, func(item: Principal): Bool { item == event.canisterId }) == null) return false;
      if (stale.size() > 0 and Array.find(stale, func(item: Bool): Bool { item == event.stale }) == null) return false;
      if (attempts.size() > 0 and Array.find(attempts, func(item: Nat): Bool { item == event.numberOfAttempts }) == null) return false;

      return true;
    });

    let limitedEvents = Utils.arraySlice(filteredEvents, params.offset, ?(Option.get(params.offset, 0) + params.limit));

    let sharedEvents = Array.map(limitedEvents, func(event: StateTypes.Event): Types.SharedEvent {{
      id = event.id;
      name = event.name;
      payload = event.payload;
      canisterId = event.canisterId;
      createdAt = event.createdAt;
      nextProcessingTime = event.nextProcessingTime;
      numberOfDispatches = event.numberOfDispatches;
      numberOfAttempts = event.numberOfAttempts;
      stale = event.stale;
      subscribers = Array.map(event.subscribers, func(item: StateTypes.Subscriber): Principal { item.canisterId });
    }});

    return { items = sharedEvents; totalCount = filteredEvents.size() };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared msg func removeStaleSubscribers() {
    if (not isAdmin(msg.caller)) throw Error.reject("Not authorized");

    for (subscriber in state.subscribers.vals()) if (subscriber.stale) subscriber.eventNames := [];

    let subscribersSize = state.subscribers.size();

    state.subscribers := Array.filter(state.subscribers, func(item: StateTypes.Subscriber): Bool { not item.stale });

    if (subscribersSize > state.subscribers.size()) updateEffectSubscribers();
  };

  public shared msg func removeStaleEvents() {
    if (not isAdmin(msg.caller)) throw Error.reject("Not authorized");

    state.events := Array.filter(state.events, func(item: StateTypes.Event): Bool { not item.stale });
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared msg func recoverStaleSubscribers() {
    if (not isAdmin(msg.caller)) throw Error.reject("Not authorized");

    for (subscriber in state.subscribers.vals()) if (subscriber.stale) {
      subscriber.stale := false;
      subscriber.firstFailedEventTime := 0;
    };
  };

  public shared msg func recoverStaleEvents() {
    if (not isAdmin(msg.caller)) throw Error.reject("Not authorized");

    for (event in state.events.vals()) if (event.stale) {
      event.stale := false;
      event.numberOfAttempts := 0;
      event.nextProcessingTime := Time.now();

      let _ = processEvent(event);
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared msg func removeSubscriber(canisterId: Principal) {
    if (not isAdmin(msg.caller)) throw Error.reject("Not authorized");

    switch (Array.find(state.subscribers, func(item: StateTypes.Subscriber): Bool { item.canisterId == canisterId })) {
      case (?subscriber) {
        subscriber.eventNames := [];
        
        state.subscribers := Array.filter(state.subscribers, func(item: StateTypes.Subscriber): Bool { item.canisterId != canisterId });

        updateEffectSubscribers();
      };

      case (_) {};
    };
  };

  public shared msg func removeEvent(id: Nat) {
    if (not isAdmin(msg.caller)) throw Error.reject("Not authorized");

    state.events := Array.filter(state.events, func(item: StateTypes.Event): Bool { item.id != id });
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared msg func recoverSubscriber(canisterId: Principal) {
    if (not isAdmin(msg.caller)) throw Error.reject("Not authorized");

    switch (Array.find(state.subscribers, func(item: StateTypes.Subscriber): Bool { item.canisterId == canisterId and item.stale })) {
      case (?subscriber) {
        subscriber.stale := false;
        subscriber.firstFailedEventTime := 0;
      };

      case (_) {};
    };
  };

  public shared msg func recoverEvent(id: Nat) {
    if (not isAdmin(msg.caller)) throw Error.reject("Not authorized");

    switch (Array.find(state.events, func(item: StateTypes.Event): Bool { item.id == id and item.stale })) {
      case (?event) {
        event.stale := false;
        event.numberOfAttempts := 0;
        event.nextProcessingTime := Time.now();

        let _ = processEvent(event);
      };

      case (_) {};
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query func getAdmins(): async [Principal] {
    return state.admins;
  };

  public shared msg func addAdmin(principalId: Principal) {
    if (not isAdmin(msg.caller)) throw Error.reject("Not authorized");

    let hasAdmin = Option.isSome(Array.find(state.admins, func(item: Principal): Bool { item != principalId }));

    if (not hasAdmin) state.admins := Array.append(state.admins, [principalId]);
  };

  public shared msg func removeAdmin(principalId: Principal) {
    if (not isAdmin(msg.caller)) throw Error.reject("Not authorized");

    state.admins := Array.filter(state.admins, func(item: Principal): Bool { item != principalId });
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  system func heartbeat(): async () {
    let _ = processEvents();
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared msg func whoami(): async Principal {
    return msg.caller;
  };
};
