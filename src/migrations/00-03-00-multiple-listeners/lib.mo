import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Map "mo:map_8_0_0_alpha_5/Map";
import Option "mo:base/Option";
import Set "mo:map_8_0_0_alpha_5/Set";
import MigrationTypes "../types";
import PrevTypes "../00-02-00-publisher-entities/types";
import Prim "mo:prim";
import Types "./types";

module {
  public func upgrade(migrationState: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    let state = switch (migrationState) { case (#v0_2_0(#data(state))) state; case (_) Debug.trap("Unexpected migration state") };

    let subscribers = Map.map<Principal, PrevTypes.Subscriber, Types.Subscriber>(state.subscribers, func(key, subscriber) = {
      id = subscriber.id;
      createdAt = subscriber.createdAt;
      var activeSubscriptions = subscriber.activeSubscriptions;
      listeners = Set.fromIter([subscriber.id].vals(), Map.phash);
      confirmedListeners = Set.fromIter([subscriber.id].vals(), Map.phash);
      subscriptions = subscriber.subscriptions;
    });

    let subscriptions = Map.map<Text, PrevTypes.SubscriptionGroup, Types.SubscriptionGroup>(state.subscriptions, func(key, subscriptionGroup) {
      return Map.map<Principal, PrevTypes.Subscription, Types.Subscription>(subscriptionGroup, func(key, subscription) = {
        eventName = subscription.eventName;
        subscriberId = subscription.subscriberId;
        createdAt = subscription.createdAt;
        var skip = subscription.skip;
        var skipped = subscription.skipped;
        var active = subscription.active;
        var stopped = subscription.stopped;
        var filter = null;
        var filterPath = null;
        var numberOfEvents = subscription.numberOfEvents;
        var numberOfNotifications = subscription.numberOfNotifications;
        var numberOfResendNotifications = subscription.numberOfResendNotifications;
        var numberOfRequestedNotifications = subscription.numberOfRequestedNotifications;
        var numberOfConfirmations = subscription.numberOfConfirmations;
        events = subscription.events;
      })
    });

    return #v0_3_0(#data({
      var eventId = state.eventId;
      var broadcastActive = state.broadcastActive;
      var nextBroadcastTime = state.nextBroadcastTime;
      admins = state.admins;
      publishers = state.publishers;
      publications = state.publications;
      subscribers = subscribers;
      subscriptions = subscriptions;
      confirmedListeners = Map.new(Map.phash);
      events = state.events;
    }));
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func downgrade(migrationState: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    let state = switch (migrationState) { case (#v0_3_0(#data(state))) state; case (_) Debug.trap("Unexpected migration state") };

    let subscribers = Map.map<Principal, Types.Subscriber, PrevTypes.Subscriber>(state.subscribers, func((key, subscriber)) = {
      id = subscriber.id;
      createdAt = subscriber.createdAt;
      var activeSubscriptions = subscriber.activeSubscriptions;
      subscriptions = subscriber.subscriptions;
    });

    let subscriptions = Map.map<Text, Types.SubscriptionGroup, PrevTypes.SubscriptionGroup>(state.subscriptions, func(key, subscriptionGroup) {
      return Map.map<Principal, Types.Subscription, PrevTypes.Subscription>(subscriptionGroup, func(key, subscription) = {
        eventName = subscription.eventName;
        subscriberId = subscription.subscriberId;
        createdAt = subscription.createdAt;
        var skip = subscription.skip;
        var skipped = subscription.skipped;
        var active = subscription.active;
        var stopped = subscription.stopped;
        var numberOfEvents = subscription.numberOfEvents;
        var numberOfNotifications = subscription.numberOfNotifications;
        var numberOfResendNotifications = subscription.numberOfResendNotifications;
        var numberOfRequestedNotifications = subscription.numberOfRequestedNotifications;
        var numberOfConfirmations = subscription.numberOfConfirmations;
        events = subscription.events;
      })
    });

    return #v0_2_0(#data({
      var eventId = state.eventId;
      var broadcastActive = state.broadcastActive;
      var nextBroadcastTime = state.nextBroadcastTime;
      admins = state.admins;
      publishers = state.publishers;
      publications = state.publications;
      subscribers = subscribers;
      subscriptions = subscriptions;
      events = state.events;
    }));
  };
};
