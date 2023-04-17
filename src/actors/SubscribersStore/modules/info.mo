import Const "../../../common/const";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Set "mo:map/Set";
import Stats "../../../common/stats";
import { n32hash; n64hash; thash; phash } "mo:map/Map";
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

    let ?subscriber = Map.get(state.subscribers, phash, subscriberId) else return null;

    var listeners = []:[Principal];
    var confirmedListeners = []:[Principal];
    var subscriptions = []:[Text];

    ignore do ?{
      if (options!.includeListeners!) listeners := Set.toArray(subscriber.listeners);
    };

    ignore do ?{
      if (options!.includeListeners!) confirmedListeners := subscriber.confirmedListeners;
    };

    ignore do ?{
      if (options!.includeSubscriptions!) subscriptions := Set.toArray(subscriber.subscriptions);
    };

    return ?{
      id = subscriber.id;
      createdAt = subscriber.createdAt;
      activeSubscriptions = subscriber.activeSubscriptions;
      listeners = listeners;
      confirmedListeners = confirmedListeners;
      subscriptions = subscriptions;
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type SubscriptionInfoResponse = ?Types.SharedSubscription;

  public type SubscriptionInfoParams = (subscriberId: Principal, eventName: Text);

  public type SubscriptionInfoFullParams = (caller: Principal, state: State.SubscribersStoreState, params: SubscriptionInfoParams);

  public func getSubscriptionInfo((caller, state, (subscriberId, eventName)): SubscriptionInfoFullParams): SubscriptionInfoResponse {
    if (caller != state.subscribersIndexId) Debug.trap(Errors.PERMISSION_DENIED);

    let ?subscriptionGroup = Map.get(state.subscriptions, thash, eventName) else return null;
    let ?subscription = Map.get(subscriptionGroup, phash, subscriberId) else return null;

    return ?{
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

    let ?subscriber = Map.get(state.subscribers, phash, subscriberId) else return Stats.empty;

    var eventNamesIter = Set.keys(subscriber.subscriptions):Set.IterNext<Text>;

    let stats = Stats.build();

    ignore do ?{
      if (options!.eventNames!.size() > Const.SUBSCRIPTIONS_LIMIT) Debug.trap(Errors.PUBLICATIONS_OPTION_LENGTH);

      eventNamesIter := options!.eventNames!.vals();
    };

    for (eventName in eventNamesIter) label iteration {
      let ?subscriptionGroup = Map.get(state.subscriptions, thash, eventName) else break iteration;
      let ?subscription = Map.get(subscriptionGroup, phash, subscriberId) else break iteration;

      ignore do ? {
        if (subscription.active != options!.active!) break iteration;
      };

      stats.numberOfEvents += subscription.stats.numberOfEvents;
      stats.numberOfNotifications += subscription.stats.numberOfNotifications;
      stats.numberOfResendNotifications += subscription.stats.numberOfResendNotifications;
      stats.numberOfRequestedNotifications += subscription.stats.numberOfRequestedNotifications;
      stats.numberOfConfirmations += subscription.stats.numberOfConfirmations;
    };

    return Stats.share(stats);
  };
};
