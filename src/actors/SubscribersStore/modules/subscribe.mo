import Array "mo:base/Array";
import CandyUtils "mo:candy_utils/CandyUtils";
import Const "../../../common/const";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Info "./info";
import Map "mo:map/Map";
import Set "mo:map/Set";
import Stats "../../../common/stats";
import { get = coalesce } "mo:base/Option";
import { time } "mo:prim";
import { unwrap } "../../../utils/misc";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type SubscriberOptions = {
    listeners: ?[Principal];
    listenersAdd: ?[Principal];
    listenersRemove: ?[Principal];
    includeListeners: ?Bool;
    includeSubscriptions: ?Bool;
  };

  public type SubscriberResponse = {
    subscriberInfo: Types.SharedSubscriber;
    prevSubscriberInfo: ?Types.SharedSubscriber;
  };

  public type SubscriberFullResponse = {
    subscriber: State.Subscriber;
    subscriberInfo: Types.SharedSubscriber;
    prevSubscriberInfo: ?Types.SharedSubscriber;
  };

  public type SubscriberParams = (subscriberId: Principal, options: ?SubscriberOptions);

  public type SubscriberFullParams = (caller: Principal, state: State.SubscribersStoreState, params: SubscriberParams);

  public func registerSubscriber((caller, state, (subscriberId, options)): SubscriberFullParams): SubscriberFullResponse {
    if (caller != state.subscribersIndexId) Debug.trap(Errors.PERMISSION_DENIED);

    let prevSubscriberInfo = Info.getSubscriberInfo(state.subscribersIndexId, state, (subscriberId, options));

    let subscriber = Map.update<Principal, State.Subscriber>(state.subscribers, phash, subscriberId, func(key, value) = coalesce(value, {
      id = subscriberId;
      createdAt = time();
      var activeSubscriptions = 0:Nat8;
      var listeners = Set.fromIter([subscriberId].vals(), phash);
      var confirmedListeners = [subscriberId];
      subscriptions = Set.new(thash);
    }));

    ignore do ?{
      if (options!.listeners!.size() > Const.LISTENERS_LIMIT) Debug.trap(Errors.LISTENERS_REPLACE_LENGTH);

      subscriber.listeners := Set.fromIter(options!.listeners!.vals(), phash);

      subscriber.confirmedListeners := Array.filter<Principal>(subscriber.confirmedListeners, func(listenerId) {
        return listenerId == subscriberId or Set.has(subscriber.listeners, phash, listenerId);
      });
    };

    ignore do ?{
      if (options!.listenersAdd!.size() > Const.LISTENERS_LIMIT) Debug.trap(Errors.LISTENERS_ADD_LENGTH);

      for (listenerId in options!.listenersAdd!.vals()) Set.add(subscriber.listeners, phash, listenerId);

      if (Set.size(subscriber.listeners) > Const.LISTENERS_LIMIT) Debug.trap(Errors.LISTENERS_LENGTH);

      subscriber.confirmedListeners := Array.filter<Principal>(subscriber.confirmedListeners, func(listenerId) {
        return listenerId == subscriberId or Set.has(subscriber.listeners, phash, listenerId);
      });
    };

    ignore do ?{
      if (options!.listenersRemove!.size() > Const.LISTENERS_LIMIT) Debug.trap(Errors.LISTENERS_REMOVE_LENGTH);

      for (principalId in options!.listenersRemove!.vals()) Set.delete(subscriber.listeners, phash, principalId);

      subscriber.confirmedListeners := Array.filter<Principal>(subscriber.confirmedListeners, func(listenerId) {
        return listenerId == subscriberId or Set.has(subscriber.listeners, phash, listenerId);
      });
    };

    let subscriberInfo = unwrap(Info.getSubscriberInfo(state.subscribersIndexId, state, (subscriberId, options)));

    return { subscriber; subscriberInfo; prevSubscriberInfo };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type SubscriptionOptions = {
    stopped: ?Bool;
    rate: ?Nat32;
    filter: ??Text;
  };

  public type SubscriptionResponse = {
    subscriptionInfo: Types.SharedSubscription;
    prevSubscriptionInfo: ?Types.SharedSubscription;
  };

  public type SubscriptionFullResponse = {
    subscription: State.Subscription;
    subscriptionInfo: Types.SharedSubscription;
    prevSubscriptionInfo: ?Types.SharedSubscription;
  };

  public type SubscriptionParams = (subscriberId: Principal, eventName: Text, options: ?SubscriptionOptions);

  public type SubscriptionFullParams = (caller: Principal, state: State.SubscribersStoreState, params: SubscriptionParams);

  public func subscribe((caller, state, (subscriberId, eventName, options)): SubscriptionFullParams): SubscriptionFullResponse {
    if (caller != state.subscribersIndexId) Debug.trap(Errors.PERMISSION_DENIED);

    let prevSubscriptionInfo = Info.getSubscriptionInfo(state.subscribersIndexId, state, (subscriberId, eventName));

    if (eventName.size() > Const.EVENT_NAME_LENGTH_LIMIT) Debug.trap(Errors.EVENT_NAME_LENGTH);

    let { subscriber } = registerSubscriber(state.subscribersIndexId, state, (subscriberId, null));

    Set.add(subscriber.subscriptions, thash, eventName);

    if (Set.size(subscriber.subscriptions) > Const.SUBSCRIPTIONS_LIMIT) Debug.trap(Errors.SUBSCRIPTIONS_LENGTH);

    let subscriptionGroup = Map.update<Text, State.SubscriptionGroup>(state.subscriptions, thash, eventName, func(key, value) {
      return coalesce<State.SubscriptionGroup>(value, Map.new(phash));
    });

    let subscription = Map.update<Principal, State.Subscription>(subscriptionGroup, phash, subscriberId, func(key, value) = coalesce(value, {
      eventName = eventName;
      subscriberId = subscriberId;
      createdAt = time();
      stats = Stats.build();
      var rate = 100:Nat32;
      var active = false;
      var stopped = false;
      var filter = null:?Text;
      var filterPath = null:?CandyUtils.Path;
      events = Set.new(nhash);
    }));

    if (not subscription.active) {
      subscription.active := true;
      subscriber.activeSubscriptions += 1;

      if (subscriber.activeSubscriptions > Const.ACTIVE_SUBSCRIPTIONS_LIMIT) Debug.trap(Errors.ACTIVE_SUBSCRIPTIONS_LENGTH);
    };

    ignore do ?{ subscription.stopped := options!.stopped! };

    ignore do ?{ subscription.rate := options!.rate! };

    ignore do ?{
      subscription.filter := options!.filter!;
      subscription.filterPath := null;

      if (options!.filter!!.size() > Const.FILTER_LENGTH_LIMIT) Debug.trap(Errors.FILTER_LENGTH);

      subscription.filterPath := ?CandyUtils.path(options!.filter!!);
    };

    let subscriptionInfo = unwrap(Info.getSubscriptionInfo(state.subscribersIndexId, state, (subscriberId, eventName)));

    return { subscription; subscriptionInfo; prevSubscriptionInfo };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type UnsubscribeOptions = {
    purge: ?Bool;
  };

  public type UnsubscribeResponse = {
    subscriptionInfo: ?Types.SharedSubscription;
    prevSubscriptionInfo: ?Types.SharedSubscription;
  };

  public type UnsubscribeParams = (subscriberId: Principal, eventName: Text, options: ?UnsubscribeOptions);

  public type UnsubscribeFullParams = (caller: Principal, state: State.SubscribersStoreState, params: UnsubscribeParams);

  public func unsubscribe((caller, state, (subscriberId, eventName, options)): UnsubscribeFullParams): UnsubscribeResponse {
    if (caller != state.subscribersIndexId) Debug.trap(Errors.PERMISSION_DENIED);

    if (eventName.size() > Const.EVENT_NAME_LENGTH_LIMIT) Debug.trap(Errors.EVENT_NAME_LENGTH);

    let prevSubscriptionInfo = Info.getSubscriptionInfo(state.subscribersIndexId, state, (subscriberId, eventName));

    ignore do ?{
      let subscriber = Map.get(state.subscribers, phash, subscriberId)!;
      let subscriptionGroup = Map.get(state.subscriptions, thash, eventName)!;
      let subscription = Map.get(subscriptionGroup, phash, subscriberId)!;

      if (subscription.active) {
        subscription.active := false;
        subscriber.activeSubscriptions -= 1;
      };

      if (options!.purge!) {
        Set.delete(subscriber.subscriptions, thash, eventName);
        Map.delete(subscriptionGroup, phash, subscriberId);

        if (Map.size(subscriptionGroup) == 0) Map.delete(state.subscriptions, thash, eventName);
      };
    };

    let subscriptionInfo = Info.getSubscriptionInfo(state.subscribersIndexId, state, (subscriberId, eventName));

    return { subscriptionInfo; prevSubscriptionInfo };
  };
};
