import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Map "mo:map_8_0_0_alpha_5/Map";
import Option "mo:base/Option";
import Set "mo:map_8_0_0_alpha_5/Set";
import MigrationTypes "../types";
import PrevMap "mo:map_4_0_0/Map";
import PrevSet "mo:map_4_0_0/Set";
import PrevTypes "../00-01-00-initial/types";
import Prim "mo:prim";
import Types "./types";

module {
  public func upgrade(migrationState: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    let state = switch (migrationState) { case (#v0_1_0(#data(state))) state; case (_) Debug.trap("Unexpected migration state") };

    let currentTime = Prim.time();
    let eventEntries = Iter.filter<(Nat, PrevTypes.Event)>(PrevMap.entries(state.events), func((key, event)) = not event.stale);
    let subscriberEntries = PrevMap.entries(state.subscribers);

    let events = Iter.map<(Nat, PrevTypes.Event), (Nat, Types.Event)>(eventEntries, func((key, event)) {
      let numberOfAttempts = Prim.natToNat8(event.numberOfAttempts);
      let eventSubscribers = Iter.map<Principal, (Principal, Nat8)>(PrevSet.keys(event.subscribers), func(key) = (key, numberOfAttempts));

      return (key, {
        id = event.id;
        eventName = event.name;
        publisherId = event.emitter;
        payload = event.payload;
        createdAt = Prim.intToNat64Wrap(event.createdAt);
        var nextBroadcastTime = Prim.intToNat64Wrap(event.nextProcessingTime);
        var numberOfAttempts = numberOfAttempts;
        resendRequests = Set.new(Map.phash);
        subscribers = Map.fromIter(eventSubscribers, Map.phash);
      });
    });

    let subscribers = Iter.map<(Principal, PrevTypes.Subscriber), (Principal, Types.Subscriber)>(subscriberEntries, func((key, subscriber)) = (key, {
      id = subscriber.canisterId;
      createdAt = Prim.intToNat64Wrap(subscriber.createdAt);
      var activeSubscriptions = Prim.natToNat8(PrevSet.size(subscriber.subscriptions));
      subscriptions = Set.fromIter(PrevSet.keys(subscriber.subscriptions), Map.thash);
    }));

    let subscriptions = Map.new<Text, Types.SubscriptionGroup>(Map.thash);

    for (subscriber in PrevMap.vals(state.subscribers)) for (eventName in PrevSet.keys(subscriber.subscriptions)) {
      let subscriberId = subscriber.canisterId;

      let subscriptionGroup = Map.update<Text, Types.SubscriptionGroup>(subscriptions, Map.thash, eventName, func(key, value) {
        return Option.get<Types.SubscriptionGroup>(value, Map.new(Map.phash));
      });

      ignore Map.update<Principal, Types.Subscription>(subscriptionGroup, Map.phash, subscriberId, func(key, value) = Option.get(value, {
        eventName = eventName;
        subscriberId = subscriberId;
        createdAt = currentTime;
        var skip = 0:Nat8;
        var skipped = 0:Nat8;
        var active = true;
        var stopped = false;
        var numberOfEvents = 0:Nat64;
        var numberOfNotifications = 0:Nat64;
        var numberOfResendNotifications = 0:Nat64;
        var numberOfRequestedNotifications = 0:Nat64;
        var numberOfConfirmations = 0:Nat64;
        events = Set.new(Map.nhash);
      }));
    };

    return #v0_2_0(#data({
      var eventId = state.eventId;
      var broadcastActive = false;
      var nextBroadcastTime = 0;
      admins = Set.fromIter(PrevSet.keys(state.admins), Map.phash);
      publishers = Map.new(Map.phash);
      publications = Map.new(Map.thash);
      subscribers = Map.fromIter(subscribers, Map.phash);
      subscriptions = subscriptions;
      events = Map.fromIter(events, Map.nhash);
    }));
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func downgrade(migrationState: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    let state = switch (migrationState) { case (#v0_2_0(#data(state))) state; case (_) Debug.trap("Unexpected migration state") };

    let currentTime = Prim.time();
    let eventEntries = Map.entries(state.events);
    let subscriberEntries = Map.entries(state.subscribers);

    let events = Iter.map<(Nat, Types.Event), (Nat, PrevTypes.Event)>(eventEntries, func((key, event)) = (key, {
      id = event.id;
      name = event.eventName;
      payload = event.payload;
      emitter = event.publisherId;
      createdAt = Prim.nat64ToNat(event.createdAt);
      var nextProcessingTime = Prim.nat64ToNat(event.nextBroadcastTime);
      var numberOfAttempts = Prim.nat8ToNat(event.numberOfAttempts);
      var stale = event.numberOfAttempts >= 8 and currentTime >= event.nextBroadcastTime;
      var subscribers = PrevSet.fromIter(Map.keys(event.subscribers), PrevMap.phash);
    }));

    let subscribers = Iter.map<(Principal, Types.Subscriber), (Principal, PrevTypes.Subscriber)>(subscriberEntries, func((key, subscriber)) = (key, {
      canisterId = subscriber.id;
      createdAt = Prim.nat64ToNat(subscriber.createdAt);
      var stale = false;
      var subscriptions = PrevSet.fromIter(Set.keys(subscriber.subscriptions), PrevMap.thash);
    }));

    return #v0_1_0(#data({
      var admins = PrevSet.fromIter(Set.keys(state.admins), PrevMap.phash);
      var eventId = state.eventId;
      var subscribers = PrevMap.fromIter(subscribers, PrevMap.phash);
      var events = PrevMap.fromIter(events, PrevMap.nhash);
    }));
  };
};
