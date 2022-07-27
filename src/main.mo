import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Candy "mo:candy/types";
import Map "mo:hashmap/Map";
import Set "mo:hashmap/Set";
import Error "mo:base/Error";
import MigrationTypes "./migrations/types";
import Migrations "./migrations";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Types "./types";
import Utils "./utils";

shared deployer actor class EventSystem() = this {
  let StateTypes = MigrationTypes.Current;

  let { nhash; thash; phash; lhash; calcHash } = Map;

  stable var migrationState: MigrationTypes.State = #v0_0_0(#data);

  migrationState := Migrations.migrate(migrationState, #v0_1_0(#id), { deployer = deployer.caller });

  let #v0_1_0(#data(state)) = migrationState;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  func isAdmin(principalId: Principal): Bool {
    return principalId == deployer.caller or principalId == Principal.fromActor(this) or Set.has(state.admins, phash, principalId);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  func removeSubscriberCascade(canisterId: Principal) {
    ignore do ? {
      let hash = calcHash(phash, canisterId);
      let subscriber = Map.remove(state.subscribers, hash, canisterId)!;

      for (event in Map.vals(state.events)) {
        Set.delete(event.subscribers, hash, canisterId);

        if (Set.size(event.subscribers) == 0) Map.delete(state.events, nhash, event.id);
      };
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  func processEvent(event: StateTypes.Event): async () {
    if (event.numberOfAttempts == 8 and Time.now() >= event.nextProcessingTime) {
      event.stale := true;

      for (subscriberId in Set.keys(event.subscribers)) ignore do ? { Map.get(state.subscribers, phash, subscriberId)!.stale := true };
    };

    if (not event.stale and Time.now() >= event.nextProcessingTime) {
      event.numberOfAttempts += 1;
      event.nextProcessingTime := Time.now() + 15 * 60 * 1000000000 * 2 ** (event.numberOfAttempts - 1);

      for (subscriberId in Set.keys(event.subscribers)) ignore do ? {
        let subscriber = Map.get(state.subscribers, phash, subscriberId)!;

        if (not subscriber.stale) {
          let subscriberActor: Types.SubscriberActor = actor(Principal.toText(subscriber.canisterId));

          subscriberActor.handleEvent(event.id, event.emitter, event.name, event.payload);
        };
      };
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared context func addSubscription(canisterId: Principal, eventName: Text): async () {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");
    if (eventName.size() > 100) throw Error.reject("Event name length limit reached");

    let subscriber = Option.get(Map.get(state.subscribers, phash, canisterId), {
      canisterId = canisterId;
      createdAt = Time.now();
      var stale = false;
      var subscriptions = Set.new<Text>();
    });

    Map.set(state.subscribers, phash, canisterId, subscriber);

    subscriber.stale := false;

    if (not Set.put(subscriber.subscriptions, thash, eventName)) {
      if (Set.size(subscriber.subscriptions) >= 100) throw Error.reject("Event subscriptions limit reached");
    };
  };

  public shared context func subscribe(eventName: Text): async () {
    await addSubscription(context.caller, eventName);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared context func removeSubscription(canisterId: Principal, eventName: Text): async () {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");
    if (eventName.size() > 100) throw Error.reject("Event name length limit reached");

    ignore do ? {
      let subscriber = Map.get(state.subscribers, phash, canisterId)!;

      Set.delete(subscriber.subscriptions, thash, eventName);

      if (Set.size(subscriber.subscriptions) == 0) removeSubscriberCascade(canisterId);
    };
  };

  public shared context func unsubscribe(eventName: Text): async () {
    await removeSubscription(context.caller, eventName);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared context func addEvent(emitter: Principal, eventName: Text, payload: Candy.CandyValue): async () {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");
    if (eventName.size() > 100) throw Error.reject("Event name length limit reached");

    let subscribers = Set.new<Principal>();
    let hash = calcHash(thash, eventName);

    for (subscriber in Map.vals(state.subscribers)) {
      if (Set.has(subscriber.subscriptions, hash, eventName)) Set.add(subscribers, phash, subscriber.canisterId);
    };

    if (Set.size(subscribers) > 0) {
      let event = {
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

      Map.set(state.events, nhash, event.id, event);

      ignore processEvent(event);
    };
  };

  public shared context func emit(eventName: Text, payload: Candy.CandyValue): async () {
    await addEvent(context.caller, eventName, payload);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared context func confirmEventProcessed(id: Nat): async () {
    ignore do ? {
      let event = Map.get(state.events, nhash, id)!;

      Set.delete(event.subscribers, phash, context.caller);

      if (Set.size(event.subscribers) == 0) Map.delete(state.events, nhash, id);
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query context func fetchSubscribers(params: Types.FetchSubscribersParams): async Types.FetchSubscribersResponse {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");

    let canisterId = do ? { Set.fromIter(params.filters!.canisterId!.vals(), phash) };
    let stale = do ? { Set.fromIter(params.filters!.stale!.vals(), lhash) };
    let subscriptions = do ? { Set.fromIter(params.filters!.subscriptions!.vals(), thash) };

    let subscribers = Iter.toArray(Map.vals(state.subscribers));

    let filteredSubscribers = Array.filter(subscribers, func(subscriber: StateTypes.Subscriber): Bool {
      ignore do ? { if (not Set.has(canisterId!, phash, subscriber.canisterId)) return false };
      ignore do ? { if (not Set.has(stale!, lhash, subscriber.stale)) return false };
      ignore do ? { if (not Set.some<Text>(subscriptions!, func(item) { Set.has(subscriber.subscriptions, thash, item) })) return false };

      return true;
    });

    let limitedSubscribers = Utils.arraySlice(filteredSubscribers, params.offset, ?(Option.get(params.offset, 0) + params.limit));

    let sharedSubscribers = Array.map(limitedSubscribers, func(subscriber: StateTypes.Subscriber): Types.SharedSubscriber {{
      canisterId = subscriber.canisterId;
      createdAt = subscriber.createdAt;
      stale = subscriber.stale;
      subscriptions = Iter.toArray(Set.keys(subscriber.subscriptions));
    }});

    return { items = sharedSubscribers; totalCount = filteredSubscribers.size() };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query context func fetchEvents(params: Types.FetchEventsParams): async Types.FetchEventsResponse {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");

    let id = do ? { Set.fromIter(params.filters!.id!.vals(), nhash) };
    let name = do ? { Set.fromIter(params.filters!.name!.vals(), thash) };
    let emitter = do ? { Set.fromIter(params.filters!.emitter!.vals(), phash) };
    let stale = do ? { Set.fromIter(params.filters!.stale!.vals(), lhash) };
    let numberOfAttempts = do ? { Set.fromIter(params.filters!.numberOfAttempts!.vals(), nhash) };

    let events = Iter.toArray(Map.vals(state.events));

    let filteredEvents = Array.filter(events, func(event: StateTypes.Event): Bool {
      ignore do ? { if (not Set.has(id!, nhash, event.id)) return false };
      ignore do ? { if (not Set.has(name!, thash, event.name)) return false };
      ignore do ? { if (not Set.has(emitter!, phash, event.emitter)) return false };
      ignore do ? { if (not Set.has(stale!, lhash, event.stale)) return false };
      ignore do ? { if (not Set.has(numberOfAttempts!, nhash, event.numberOfAttempts)) return false };

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
      subscribers = Iter.toArray(Set.keys(event.subscribers));
    }});

    return { items = sharedEvents; totalCount = filteredEvents.size() };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared context func removeStaleSubscribers(): async () {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");

    for (subscriber in Map.vals(state.subscribers)) if (subscriber.stale) removeSubscriberCascade(subscriber.canisterId);
  };

  public shared context func removeStaleEvents(): async () {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");

    for (event in Map.vals(state.events)) if (event.stale) Map.delete(state.events, nhash, event.id);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared context func recoverStaleSubscribers(): async () {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");

    for (subscriber in Map.vals(state.subscribers)) if (subscriber.stale) subscriber.stale := false;
  };

  public shared context func recoverStaleEvents(): async () {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");

    for (event in Map.vals(state.events)) if (event.stale) {
      event.stale := false;
      event.numberOfAttempts := 0;
      event.nextProcessingTime := Time.now();

      ignore processEvent(event);
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared context func removeSubscriber(canisterId: Principal): async () {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");

    removeSubscriberCascade(canisterId);
  };

  public shared context func removeEvent(id: Nat): async () {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");

    Map.delete(state.events, nhash, id);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared context func recoverSubscriber(canisterId: Principal): async () {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");

    ignore do ? { Map.get(state.subscribers, phash, canisterId)!.stale := false };
  };

  public shared context func recoverEvent(id: Nat): async () {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");

    ignore do ? {
      let event = Map.get(state.events, nhash, id)!;

      if (not event.stale) {
        event.stale := false;
        event.numberOfAttempts := 0;
        event.nextProcessingTime := Time.now();

        ignore processEvent(event);
      };
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query func getAdmins(): async [Principal] {
    return Iter.toArray(Set.keys(state.admins));
  };

  public shared context func addAdmin(principalId: Principal): async () {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");

    Set.add(state.admins, phash, principalId);
  };

  public shared context func removeAdmin(principalId: Principal): async () {
    if (not isAdmin(context.caller)) throw Error.reject("Not authorized");

    Set.delete(state.admins, phash, principalId);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  system func heartbeat(): async () {
    for (event in Map.vals(state.events)) if (not event.stale and Time.now() >= event.nextProcessingTime) ignore processEvent(event);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query context func whoami(): async Principal {
    return context.caller;
  };
};
