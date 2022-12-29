import Const "../../../common/const";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Set "mo:map/Set";
import Stats "../../../common/stats";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type SubscriberInfoOptions = {
    includeListeners: ?Bool;
    includeSubscriptions: ?Bool;
  };

  public type SubscriberInfoResponse = ?Types.SharedSubscriber;

  public type SubscriberInfoParams = (subscriberId: Principal, options: ?SubscriberInfoOptions);

  public type SubscriberInfoFullParams = (caller: Principal, state: State.SubscribersStoreState, params: SubscriberInfoParams);

  public func getSubscriberInfo((caller, state, (subscriberId, options)): SubscriberInfoFullParams): SubscriberInfoResponse {
    if (caller != state.subscribersIndexId) Debug.trap(Errors.PERMISSION_DENIED);

    var result = null:?Types.SharedSubscriber;

    ignore do ?{
      let subscriber = Map.get(state.subscribers, phash, subscriberId)!;

      var listeners = []:[Principal];
      var confirmedListeners = []:[Principal];
      var subscriptions = []:[Text];

      ignore do ?{ if (options!.includeListeners!) listeners := Set.toArray(subscriber.listeners) };

      ignore do ?{ if (options!.includeListeners!) confirmedListeners := subscriber.confirmedListeners };

      ignore do ?{ if (options!.includeSubscriptions!) subscriptions := Set.toArray(subscriber.subscriptions) };

      result := ?{
        id = subscriber.id;
        createdAt = subscriber.createdAt;
        activeSubscriptions = subscriber.activeSubscriptions;
        listeners = listeners;
        confirmedListeners = confirmedListeners;
        subscriptions = subscriptions;
      };
    };

    return result;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type SubscriptionInfoResponse = ?Types.SharedSubscription;

  public type SubscriptionInfoParams = (subscriberId: Principal, eventName: Text);

  public type SubscriptionInfoFullParams = (caller: Principal, state: State.SubscribersStoreState, params: SubscriptionInfoParams);

  public func getSubscriptionInfo((caller, state, (subscriberId, eventName)): SubscriptionInfoFullParams): SubscriptionInfoResponse {
    if (caller != state.subscribersIndexId) Debug.trap(Errors.PERMISSION_DENIED);

    var result = null:?Types.SharedSubscription;

    ignore do ?{
      let subscriptionGroup = Map.get(state.subscriptions, thash, eventName)!;
      let subscription = Map.get(subscriptionGroup, phash, subscriberId)!;

      result := ?{
        eventName = subscription.eventName;
        subscriberId = subscription.subscriberId;
        createdAt = subscription.createdAt;
        stats = Stats.share(subscription.stats);
        rate = subscription.rate;
        active = subscription.active;
        stopped = subscription.stopped;
        filter = subscription.filter;
      };
    };

    return result;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type SubscriptionStatsOptions = {
    active: ?Bool;
    eventNames: ?[Text];
  };

  public type SubscriptionStatsResponse = Types.SharedStats;

  public type SubscriptionStatsParams = (subscriberId: Principal, options: ?SubscriptionStatsOptions);

  public type SubscriptionStatsFullParams = (caller: Principal, state: State.SubscribersStoreState, params: SubscriptionStatsParams);

  public func getSubscriptionStats((caller, state, (subscriberId, options)): SubscriptionStatsFullParams): SubscriptionStatsResponse {
    if (caller != state.subscribersIndexId) Debug.trap(Errors.PERMISSION_DENIED);

    let stats = Stats.build();

    ignore do ?{
      let subscriber = Map.get(state.subscribers, phash, subscriberId)!;

      var eventNamesIter = Set.keys(subscriber.subscriptions):Set.IterNext<Text>;

      ignore do ?{
        if (options!.eventNames!.size() > Const.PUBLICATIONS_LIMIT) Debug.trap(Errors.PUBLICATIONS_LENGTH);

        eventNamesIter := options!.eventNames!.vals();
      };

      for (eventName in eventNamesIter) label iteration ignore do ?{
        let subscriptionGroup = Map.get(state.subscriptions, thash, eventName)!;
        let subscription = Map.get(subscriptionGroup, phash, subscriberId)!;

        ignore do ? { if (subscription.active != options!.active!) break iteration };

        stats.numberOfEvents += subscription.stats.numberOfEvents;
        stats.numberOfNotifications += subscription.stats.numberOfNotifications;
        stats.numberOfResendNotifications += subscription.stats.numberOfResendNotifications;
        stats.numberOfRequestedNotifications += subscription.stats.numberOfRequestedNotifications;
        stats.numberOfConfirmations += subscription.stats.numberOfConfirmations;
      };
    };

    return Stats.share(stats);
  };
};
