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

  migrationState := Migrations.migrate(migrationState, #state002(#id), { deployer = deployer.caller });

  let #state002(#data(state)) = migrationState;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  func isAdmin(principalId: Principal): Bool {
    if (principalId == deployer.caller or principalId == Principal.fromActor(this)) return true;

    for (admin in state.admins.vals()) if (principalId == admin) return true;

    return false;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  func updateEventSubscribers() {
    for (event in state.events.vals()) event.subscribers := Array.filter(event.subscribers, func(subscriber: StateTypes.Subscriber): Bool {
      return Option.isSome(Array.find(subscriber.subscriptions, func(item: Text): Bool { item == event.name }));
    });

    state.events := Array.filter(state.events, func(item: StateTypes.Event): Bool { item.subscribers.size() > 0 });
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  func processEvent(event: StateTypes.Event): async () {
    if (event.numberOfAttempts == 8 and Time.now() >= event.nextProcessingTime) {
      event.stale := true;

      for (subscriber in event.subscribers.vals()) subscriber.stale := true;
    };

    if (not event.stale and Time.now() >= event.nextProcessingTime) {
      event.numberOfAttempts += 1;
      event.nextProcessingTime := Time.now() + 15 * 60 * 1000000000 * 2 ** (event.numberOfAttempts - 1);

      for (subscriber in event.subscribers.vals()) if (not subscriber.stale) {
        let subscriberActor: Types.SubscriberActor = actor(Principal.toText(subscriber.canisterId));

        subscriberActor.handleEvent(event.id, event.emitter, event.name, event.payload);
      };
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared context func addSubscription(canisterId: Principal, eventName: Text): async () {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");
    if (eventName.size() > 100) throw Error.reject("Event name length limit reached");

    switch (Array.find(state.subscribers, func(item: StateTypes.Subscriber): Bool { item.canisterId == canisterId })) {
      case (?subscriber) {
        if (subscriber.subscriptions.size() >= 100) throw Error.reject("Event subscriptions limit reached");

        subscriber.stale := false;

        let hasEvent = Option.isSome(Array.find(subscriber.subscriptions, func(item: Text): Bool { item == eventName }));

        if (not hasEvent) subscriber.subscriptions := Array.append(subscriber.subscriptions, [eventName]);
      };

      case (_) {
        let subscriber: StateTypes.Subscriber = {
          canisterId = canisterId;
          createdAt = Time.now();
          var stale = false;
          var subscriptions = [eventName];
        };

        state.subscribers := Array.append(state.subscribers, [subscriber]);
      };
    };
  };

  public shared context func subscribe(eventName: Text): async () {
    await addSubscription(context.caller, eventName);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared context func removeSubscription(canisterId: Principal, eventName: Text): async () {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");
    if (eventName.size() > 100) throw Error.reject("Event name length limit reached");

    for (subscriber in state.subscribers.vals()) if (subscriber.canisterId == canisterId) {
      let subscriptionsSize = subscriber.subscriptions.size();

      subscriber.subscriptions := Array.filter(subscriber.subscriptions, func(item: Text): Bool { item != eventName });

      if (subscriptionsSize > subscriber.subscriptions.size()) updateEventSubscribers();

      if (subscriber.subscriptions.size() == 0) {
        state.subscribers := Array.filter(state.subscribers, func(item: StateTypes.Subscriber): Bool { item.canisterId != subscriber.canisterId });
      };
    };
  };

  public shared context func unsubscribe(eventName: Text): async () {
    await removeSubscription(context.caller, eventName);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared context func addEvent(emitter: Principal, eventName: Text, payload: Candy.CandyValue): async () {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");
    if (eventName.size() > 100) throw Error.reject("Event name length limit reached");

    let subscribers = Array.filter(state.subscribers, func(subscriber: StateTypes.Subscriber): Bool {
      return Option.isSome(Array.find(subscriber.subscriptions, func(item: Text): Bool { item == eventName }));
    });

    if (subscribers.size() > 0) {
      let event: StateTypes.Event = {
        id = state.eventId;
        name = eventName;
        payload = payload;
        emitter = emitter;
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

  public shared context func emit(eventName: Text, payload: Candy.CandyValue): async () {
    await addEvent(context.caller, eventName, payload);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared context func confirmEventProcessed(id: Nat): async () {
    for (event in state.events.vals()) if (event.id == id) {
      for (subscriber in event.subscribers.vals()) if (subscriber.canisterId == context.caller) subscriber.stale := false;

      event.subscribers := Array.filter(event.subscribers, func(item: StateTypes.Subscriber): Bool { item.canisterId != context.caller });

      if (event.subscribers.size() == 0) state.events := Array.filter(state.events, func(item: StateTypes.Event): Bool { item.id != id });
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query context func fetchSubscribers(params: Types.FetchSubscribersParams): async Types.FetchSubscribersResponse {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");

    let canisterId = switch (params.filters) { case (?filters) Option.get(filters.canisterId, []); case (_) [] };
    let stale = switch (params.filters) { case (?filters) Option.get(filters.stale, []); case (_) [] };
    let subscriptions = switch (params.filters) { case (?filters) Option.get(filters.subscriptions, []); case (_) [] };

    let filteredSubscribers = Array.filter(state.subscribers, func(subscriber: StateTypes.Subscriber): Bool {
      if (canisterId.size() > 0 and Array.find(canisterId, func(item: Principal): Bool { item == subscriber.canisterId }) == null) return false;
      if (stale.size() > 0 and Array.find(stale, func(item: Bool): Bool { item == subscriber.stale }) == null) return false;

      if (subscriptions.size() > 0) {
        let hasIntersectingSubscriptions = Option.isSome(Array.find(subscriptions, func(subscription: Text): Bool { 
          return Option.isSome(Array.find(subscriber.subscriptions, func(item: Text): Bool { item == subscription }));
        }));

        if (not hasIntersectingSubscriptions) return false;
      };

      return true;
    });

    let limitedSubscribers = Utils.arraySlice(filteredSubscribers, params.offset, ?(Option.get(params.offset, 0) + params.limit));

    let sharedSubscribers = Array.map(limitedSubscribers, func(subscriber: StateTypes.Subscriber): Types.SharedSubscriber {{
      canisterId = subscriber.canisterId;
      createdAt = subscriber.createdAt;
      stale = subscriber.stale;
      subscriptions = subscriber.subscriptions;
    }});

    return { items = sharedSubscribers; totalCount = filteredSubscribers.size() };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query context func fetchEvents(params: Types.FetchEventsParams): async Types.FetchEventsResponse {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");

    let id = switch (params.filters) { case (?filters) Option.get(filters.id, []); case (_) [] };
    let name = switch (params.filters) { case (?filters) Option.get(filters.name, []); case (_) [] };
    let emitter = switch (params.filters) { case (?filters) Option.get(filters.emitter, []); case (_) [] };
    let stale = switch (params.filters) { case (?filters) Option.get(filters.stale, []); case (_) [] };
    let attempts = switch (params.filters) { case (?filters) Option.get(filters.numberOfAttempts, []); case (_) [] };

    let filteredEvents = Array.filter(state.events, func(event: StateTypes.Event): Bool {
      if (id.size() > 0 and Array.find(id, func(item: Nat): Bool { item == event.id }) == null) return false;
      if (name.size() > 0 and Array.find(name, func(item: Text): Bool { item == event.name }) == null) return false;
      if (emitter.size() > 0 and Array.find(emitter, func(item: Principal): Bool { item == event.emitter }) == null) return false;
      if (stale.size() > 0 and Array.find(stale, func(item: Bool): Bool { item == event.stale }) == null) return false;
      if (attempts.size() > 0 and Array.find(attempts, func(item: Nat): Bool { item == event.numberOfAttempts }) == null) return false;

      return true;
    });

    let limitedEvents = Utils.arraySlice(filteredEvents, params.offset, ?(Option.get(params.offset, 0) + params.limit));

    let sharedEvents = Array.map(limitedEvents, func(event: StateTypes.Event): Types.SharedEvent {{
      id = event.id;
      name = event.name;
      payload = event.payload;
      emitter = event.emitter;
      createdAt = event.createdAt;
      nextProcessingTime = event.nextProcessingTime;
      numberOfAttempts = event.numberOfAttempts;
      stale = event.stale;
      subscribers = Array.map(event.subscribers, func(item: StateTypes.Subscriber): Principal { item.canisterId });
    }});

    return { items = sharedEvents; totalCount = filteredEvents.size() };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared context func removeStaleSubscribers(): async () {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");

    for (subscriber in state.subscribers.vals()) if (subscriber.stale) subscriber.subscriptions := [];

    let subscribersSize = state.subscribers.size();

    state.subscribers := Array.filter(state.subscribers, func(item: StateTypes.Subscriber): Bool { not item.stale });

    if (subscribersSize > state.subscribers.size()) updateEventSubscribers();
  };

  public shared context func removeStaleEvents(): async () {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");

    state.events := Array.filter(state.events, func(item: StateTypes.Event): Bool { not item.stale });
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared context func recoverStaleSubscribers(): async () {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");

    for (subscriber in state.subscribers.vals()) if (subscriber.stale) subscriber.stale := false;
  };

  public shared context func recoverStaleEvents(): async () {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");

    for (event in state.events.vals()) if (event.stale) {
      event.stale := false;
      event.numberOfAttempts := 0;
      event.nextProcessingTime := Time.now();

      let _ = processEvent(event);
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared context func removeSubscriber(canisterId: Principal): async () {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");

    for (subscriber in state.subscribers.vals()) if (subscriber.canisterId == canisterId) {
      subscriber.subscriptions := [];

      state.subscribers := Array.filter(state.subscribers, func(item: StateTypes.Subscriber): Bool { item.canisterId != canisterId });

      updateEventSubscribers();
    };
  };

  public shared context func removeEvent(id: Nat): async () {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");

    state.events := Array.filter(state.events, func(item: StateTypes.Event): Bool { item.id != id });
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared context func recoverSubscriber(canisterId: Principal): async () {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");

    for (subscriber in state.subscribers.vals()) if (subscriber.canisterId == canisterId) subscriber.stale := false;
  };

  public shared context func recoverEvent(id: Nat): async () {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");

    for (event in state.events.vals()) if (event.id == id and event.stale) {
      event.stale := false;
      event.numberOfAttempts := 0;
      event.nextProcessingTime := Time.now();

      let _ = processEvent(event);
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query func getAdmins(): async [Principal] {
    return state.admins;
  };

  public shared context func addAdmin(principalId: Principal): async () {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");

    let hasAdmin = Option.isSome(Array.find(state.admins, func(item: Principal): Bool { item != principalId }));

    if (not hasAdmin) state.admins := Array.append(state.admins, [principalId]);
  };

  public shared context func removeAdmin(principalId: Principal): async () {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");

    state.admins := Array.filter(state.admins, func(item: Principal): Bool { item != principalId });
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  system func heartbeat(): async () {
    for (event in state.events.vals()) if (not event.stale and Time.now() >= event.nextProcessingTime) let _ = processEvent(event);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query context func whoami(): async Principal {
    return context.caller;
  };
};
