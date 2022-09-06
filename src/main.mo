import Array "mo:base/Array";
import Candy "mo:candy/types";
import Debug "mo:base/Debug";
import Map "mo:map/Map";
import MigrationTypes "./migrations/types";
import Migrations "./migrations";
import Option "mo:base/Option";
import Prim "mo:prim";
import Principal "mo:base/Principal";
import Set "mo:map/Set";
import Types "./types";
import Utils "./utils/misc";

shared ({ caller = deployer }) actor class EventSystem() {
  let State = MigrationTypes.Current;

  let { get = coalesce } = Option;

  let { pthash; arraySlice } = Utils;

  let { nhash; thash; phash; lhash; calcHash } = Map;

  let { nat64ToNat = nat; natToNat64 = nat64; time } = Prim;

  let RESEND_DELAY: Nat64 = 15 * 60 * 1_000_000_000;

  let BROADCAST_DELAY: Nat64 = 3 * 60 * 1_000_000_000;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  stable var migrationState: MigrationTypes.State = #v0_0_0(#data);

  migrationState := Migrations.migrate(migrationState, #v0_1_0(#id), {});

  let state = switch (migrationState) { case (#v0_1_0(#data(state))) state; case (_) Debug.trap("Unexpected migration state") };

  let { admins = stateAdmins; subscribers = stateSubscribers; subscriptions = stateSubscriptions; events = stateEvents } = state;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  func isAdmin(principalId: Principal): Bool {
    return principalId == deployer or Set.has(stateAdmins, phash, principalId);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  func removeEventCascade(eventId: Nat) {
    ignore do ?{
      let event = Map.remove(stateEvents, nhash, eventId)!;
      let eventName = event.eventName;

      for (subscriberId in Set.keys(event.subscribers)) ignore do ?{
        let subscription = Map.get(stateSubscriptions, pthash, (subscriberId, eventName))!;

        Set.delete(subscription.events, nhash, eventId);
      };
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  func removeSubscriberCascade(subscriberId: Principal) {
    ignore do ?{
      let subscriberIdHash = calcHash(phash, subscriberId);
      let subscriber = Map.remove(stateSubscribers, subscriberIdHash, subscriberId)!;

      for (eventName in Set.keys(subscriber.subscriptions)) ignore do ?{
        let subscription = Map.remove(stateSubscriptions, pthash, (subscriberId, eventName))!;

        for (eventId in Set.keys(subscription.events)) ignore do ?{
          let event = Map.get(stateEvents, nhash, eventId)!;

          Set.delete(event.subscribers, subscriberIdHash, subscriberId);

          if (Set.size(event.subscribers) == 0) removeEventCascade(eventId);
        };
      };
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  func processEvent(event: State.Event): async () {
    if (event.numberOfAttempts < 8) {
      let { eventId; eventName; payload; publisherId } = event;

      event.numberOfAttempts += 1;
      event.nextResendTime := time() + RESEND_DELAY * 2 ** (event.numberOfAttempts - 1);

      for (subscriberId in Set.keys(event.subscribers)) ignore do ?{
        let subscription = Map.get(stateSubscriptions, pthash, (subscriberId, eventName))!;

        if (subscription.active and not subscription.stopped) {
          let subscriberActor: Types.SubscriberActor = actor(Principal.toText(subscriberId));

          subscriberActor.handleEvent(eventId, publisherId, eventName, payload);
        };
      };
    } else {
      removeEventCascade(event.eventId);
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared ({ caller }) func subscribe(eventName: Text, options: Types.SubscriptionOptions): async () {
    if (eventName.size() > 50) Debug.trap("Event name length limit reached");
    if (options.size() > 2) Debug.trap("Invalid number of options");

    let subId = (caller, eventName);

    let subscriber = Map.update<Principal, State.Subscriber>(stateSubscribers, phash, caller, func(key, value) = coalesce(value, {
      subscriberId = caller;
      createdAt = time();
      var activeSubscriptions = 0:Nat32;
      subscriptions = Set.new(thash);
    }));

    let subscription = Map.update<State.SubId, State.Subscription>(stateSubscriptions, pthash, subId, func(key, value) = coalesce(value, {
      eventName = eventName;
      subscriberId = caller;
      createdAt = time();
      var skip = 0:Nat32;
      var skipped = 0:Nat32;
      var active = false;
      var stopped = false;
      events = Set.new(nhash);
    }));

    if (not subscription.active) {
      subscription.active := true;
      subscriber.activeSubscriptions +%= 1;
    };

    for (option in options.vals()) switch (option) {
      case (#stopped(stopped)) subscription.stopped := stopped;
      case (#skip(skip)) subscription.skip := skip;
    };

    Set.add(subscriber.subscriptions, thash, eventName);

    if (subscriber.activeSubscriptions > 100) Debug.trap("Active subscriptions limit reached");
    if (Set.size(subscriber.subscriptions) > 500) Debug.trap("Subscriptions limit reached");
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared ({ caller }) func unsubscribe(eventName: Text, options: Types.UnsubscribeOptions): async () {
    if (eventName.size() > 50) Debug.trap("Event name length limit reached");
    if (options.size() > 1) Debug.trap("Invalid number of options");

    ignore do ?{
      let subscriber = Map.get(stateSubscribers, phash, caller)!;
      let subscription = Map.get(stateSubscriptions, pthash, (caller, eventName))!;

      if (subscription.active) {
        subscription.active := false;
        subscriber.activeSubscriptions -%= 1;
      };

      for (option in options.vals()) switch (option) {
        case (#purge) {
          Set.delete(subscriber.subscriptions, thash, eventName);
          Map.delete(stateSubscriptions, pthash, (caller, eventName));
        };
      };
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared ({ caller }) func publish(eventName: Text, payload: Candy.CandyValue): async () {
    if (eventName.size() > 50) Debug.trap("Event name length limit reached");

    let eventId = state.eventId;
    let subscribers = Set.new(phash);

    for (subscriberId in Map.keys(stateSubscribers)) ignore do ?{
      let subscription = Map.get(stateSubscriptions, pthash, (subscriberId, eventName))!;

      if (subscription.active) if (subscription.skipped >= subscription.skip) {
        subscription.skipped := 0;

        Set.add(subscribers, phash, subscriberId);
        Set.add(subscription.events, nhash, eventId);
      } else {
        subscription.skipped += 1;
      };
    };

    if (Set.size(subscribers) > 0) {
      let event: State.Event = {
        eventId = eventId;
        eventName = eventName;
        payload = payload;
        publisherId = caller;
        createdAt = time();
        var nextResendTime = time();
        var numberOfAttempts = 0;
        subscribers = subscribers;
      };

      Map.set(stateEvents, nhash, eventId, event);

      state.eventId += 1;

      ignore processEvent(event);
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared ({ caller }) func requestMissedEvents(eventName: Text, options: Types.MissedEventOptions): async () {
    if (eventName.size() > 50) Debug.trap("Event name length limit reached");
    if (options.size() > 2) Debug.trap("Invalid number of options");

    ignore do ?{
      let subscription = Map.get(stateSubscriptions, pthash, (caller, eventName))!;
      let subscriberActor = actor(Principal.toText(caller)):Types.SubscriberActor;
      var from = 0:Nat64;
      var to = 0:Nat64 -% 1;

      for (option in options.vals()) switch (option) {
        case (#from(value)) from := value;
        case (#to(value)) to := value;
      };

      for (eventId in Set.keys(subscription.events)) ignore do ?{
        let event = Map.get(stateEvents, nhash, eventId)!;

        if (event.createdAt >= from and event.createdAt <= to) {
          subscriberActor.handleEvent(event.eventId, event.publisherId, event.eventName, event.payload);
        };
      };
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared ({ caller }) func confirmEventProcessed(eventId: Nat): async () {
    ignore do ?{
      let event = Map.get(stateEvents, nhash, eventId)!;

      Set.delete(event.subscribers, phash, caller);

      if (Set.size(event.subscribers) == 0) removeEventCascade(eventId);
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query ({ caller }) func fetchSubscribers(params: Types.FetchSubscribersParams): async Types.FetchSubscribersResponse {
    if (not isAdmin(caller)) Debug.trap("Not authorized");

    let subscriberId = do ?{ Set.fromIter(params.filters!.subscriberId!.vals(), phash) };
    let subscriptions = do ?{ Set.fromIter(params.filters!.subscriptions!.vals(), thash) };

    let subscribers = Map.toArray<Principal, State.Subscriber, State.Subscriber>(stateSubscribers, func(key, value) = ?value);

    let filteredSubscribers = Array.filter(subscribers, func(subscriber: State.Subscriber): Bool {
      ignore do ?{ if (not Set.has(subscriberId!, phash, subscriber.subscriberId)) return false };
      ignore do ?{ if (not Set.some<Text>(subscriptions!, func(item) = Set.has(subscriber.subscriptions, thash, item))) return false };

      return true;
    });

    let limitedSubscribers = arraySlice(filteredSubscribers, params.offset, ?(coalesce(params.offset, 0) + params.limit));

    let sharedSubscribers = Array.map(limitedSubscribers, func(subscriber: State.Subscriber): Types.SharedSubscriber {{
      subscriberId = subscriber.subscriberId;
      createdAt = subscriber.createdAt;
      activeSubscriptions = subscriber.activeSubscriptions;
      subscriptions = Set.toArray<Text, Text>(subscriber.subscriptions, func(key) = ?key);
    }});

    return { items = sharedSubscribers; totalCount = filteredSubscribers.size() };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query ({ caller }) func fetchEvents(params: Types.FetchEventsParams): async Types.FetchEventsResponse {
    if (not isAdmin(caller)) Debug.trap("Not authorized");

    let eventId = do ?{ Set.fromIter(params.filters!.eventId!.vals(), nhash) };
    let eventName = do ?{ Set.fromIter(params.filters!.eventName!.vals(), thash) };
    let publisherId = do ?{ Set.fromIter(params.filters!.publisherId!.vals(), phash) };
    let numberOfAttempts = do ?{ Set.fromIter(params.filters!.numberOfAttempts!.vals(), nhash) };

    let events = Map.toArray<Nat, State.Event, State.Event>(stateEvents, func(key, value) = ?value);

    let filteredEvents = Array.filter(events, func(event: State.Event): Bool {
      ignore do ?{ if (not Set.has(eventId!, nhash, event.eventId)) return false };
      ignore do ?{ if (not Set.has(eventName!, thash, event.eventName)) return false };
      ignore do ?{ if (not Set.has(publisherId!, phash, event.publisherId)) return false };
      ignore do ?{ if (not Set.has(numberOfAttempts!, nhash, nat(event.numberOfAttempts))) return false };

      return true;
    });

    let limitedEvents = arraySlice(filteredEvents, params.offset, ?(coalesce(params.offset, 0) + params.limit));

    let sharedEvents = Array.map(limitedEvents, func(event: State.Event): Types.SharedEvent {{
      eventId = event.eventId;
      eventName = event.eventName;
      payload = event.payload;
      publisherId = event.publisherId;
      createdAt = event.createdAt;
      nextResendTime = event.nextResendTime;
      numberOfAttempts = event.numberOfAttempts;
      subscribers = Set.toArray<Principal, Principal>(event.subscribers, func(key) = ?key);
    }});

    return { items = sharedEvents; totalCount = filteredEvents.size() };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared ({ caller }) func removeSubscribers(subscriberIds: [Principal]): async () {
    if (not isAdmin(caller)) Debug.trap("Not authorized");

    for (subscriberId in subscriberIds.vals()) removeSubscriberCascade(subscriberId);
  };

  public shared ({ caller }) func removeEvents(eventIds: [Nat]): async () {
    if (not isAdmin(caller)) Debug.trap("Not authorized");

    for (eventId in eventIds.vals()) removeEventCascade(eventId);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query ({ caller }) func getAdmins(): async [Principal] {
    if (not isAdmin(caller)) Debug.trap("Not authorized");

    return Set.toArray<Principal, Principal>(stateAdmins, func(key) = ?key);
  };

  public shared ({ caller }) func addAdmin(principalId: Principal): async () {
    if (not isAdmin(caller)) Debug.trap("Not authorized");

    Set.add(stateAdmins, phash, principalId);
  };

  public shared ({ caller }) func removeAdmin(principalId: Principal): async () {
    if (not isAdmin(caller)) Debug.trap("Not authorized");

    Set.delete(stateAdmins, phash, principalId);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  system func heartbeat(): async () {
    let currentTime = time();

    if (currentTime > state.nextBroadcastTime) {
      state.nextBroadcastTime := currentTime + BROADCAST_DELAY;

      for (event in Map.vals(stateEvents)) if (currentTime >= event.nextResendTime) ignore processEvent(event);
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query ({ caller }) func whoami(): async Principal {
    return caller;
  };

  public query func getTime(): async Nat64 {
    return time();
  };
};
