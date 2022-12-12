import Array "mo:base/Array";
import CandyUtils "mo:candy_utils/CandyUtils";
import Const "../../../common/const";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Inform "./inform";
import Map "mo:map/Map";
import MigrationTypes "../../../migrations/types";
import Option "mo:base/Option";
import Prim "mo:prim";
import Set "mo:map/Set";
import Stats "../../../common/stats";
import Types "../../../common/types";
import Utils "../../../utils/misc";

module {
  let State = MigrationTypes.Current;

  let { get = coalesce } = Option;

  let { path } = CandyUtils;

  let { unwrap } = Utils;

  let { nhash; thash; phash; lhash } = Map;

  let { time } = Prim;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type SubscriberOptions = {
    listeners: ?[Principal];
    listenersAdd: ?[Principal];
    listenersRemove: ?[Principal];
    includeListeners: ?Bool;
    includeSubscriptions: ?Bool;
  };

  public type SubscriberInfo = {
    subscriberInfo: Types.SharedSubscriber;
    prevSubscriberInfo: ?Types.SharedSubscriber;
  };

  public type SubscriberResponse = {
    subscriber: State.Subscriber;
    subscriberInfo: Types.SharedSubscriber;
    prevSubscriberInfo: ?Types.SharedSubscriber;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type SubscriptionOptions = {
    stopped: ?Bool;
    rate: ?Nat8;
    filter: ??Text;
  };

  public type SubscriptionInfo = {
    subscriptionInfo: Types.SharedSubscription;
    prevSubscriptionInfo: ?Types.SharedSubscription;
  };

  public type SubscriptionResponse = {
    subscription: State.Subscription;
    subscriptionInfo: Types.SharedSubscription;
    prevSubscriptionInfo: ?Types.SharedSubscription;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type UnsubscribeOptions = {
    purge: ?Bool;
  };

  public type UnsubscribeResponse = {
    subscriptionInfo: ?Types.SharedSubscription;
    prevSubscriptionInfo: ?Types.SharedSubscription;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.SubscribersStoreState, deployer: Principal): {
    registerSubscriber: (caller: Principal, subscriberId: Principal, options: ?SubscriberOptions) -> SubscriberResponse;
    subscribe: (caller: Principal, subscriberId: Principal, eventName: Text, options: ?SubscriptionOptions) -> SubscriptionResponse;
    unsubscribe: (caller: Principal, subscriberId: Principal, eventName: Text, options: ?UnsubscribeOptions) -> UnsubscribeResponse;
  } = object {
    let { subscribers; subscriptions } = state;

    let InfoModule = Inform.init(state, deployer);

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func registerSubscriber(caller: Principal, subscriberId: Principal, options: ?SubscriberOptions): SubscriberResponse {
      if (caller != deployer) Debug.trap(Errors.PERMISSION_DENIED);

      let prevSubscriberInfo = InfoModule.getSubscriberInfo(caller, subscriberId, options);

      let subscriber = Map.update<Principal, State.Subscriber>(subscribers, phash, subscriberId, func(key, value) = coalesce(value, {
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

      let subscriberInfo = unwrap(InfoModule.getSubscriberInfo(caller, subscriberId, options));

      return { subscriber; subscriberInfo; prevSubscriberInfo };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func subscribe(caller: Principal, subscriberId: Principal, eventName: Text, options: ?SubscriptionOptions): SubscriptionResponse {
      if (caller != deployer) Debug.trap(Errors.PERMISSION_DENIED);

      let prevSubscriptionInfo = InfoModule.getSubscriptionInfo(caller, subscriberId, eventName);

      if (eventName.size() > Const.EVENT_NAME_LENGTH_LIMIT) Debug.trap(Errors.EVENT_NAME_LENGTH);

      let { subscriber } = registerSubscriber(caller, subscriberId, null);

      Set.add(subscriber.subscriptions, thash, eventName);

      if (Set.size(subscriber.subscriptions) > Const.SUBSCRIPTIONS_LIMIT) Debug.trap(Errors.SUBSCRIPTIONS_LENGTH);

      let subscriptionGroup = Map.update<Text, State.SubscriptionGroup>(subscriptions, thash, eventName, func(key, value) {
        return coalesce<State.SubscriptionGroup>(value, Map.new(phash));
      });

      let subscription = Map.update<Principal, State.Subscription>(subscriptionGroup, phash, subscriberId, func(key, value) = coalesce(value, {
        eventName = eventName;
        subscriberId = subscriberId;
        createdAt = time();
        stats = Stats.defaultStats();
        var rate = 100:Nat8;
        var active = false;
        var stopped = false;
        var filter = null:?Text;
        var filterPath = null:?CandyUtils.Path;
        events = Set.new(nhash);
      }));

      if (not subscription.active) {
        subscription.active := true;
        subscriber.activeSubscriptions +%= 1;

        if (subscriber.activeSubscriptions > Const.ACTIVE_SUBSCRIPTIONS_LIMIT) Debug.trap(Errors.ACTIVE_SUBSCRIPTIONS_LENGTH);
      };

      ignore do ?{ subscription.stopped := options!.stopped! };

      ignore do ?{ subscription.rate := options!.rate! };

      ignore do ?{
        subscription.filter := options!.filter!;
        subscription.filterPath := null;

        if (options!.filter!!.size() > Const.FILTER_LENGTH_LIMIT) Debug.trap(Errors.FILTER_LENGTH);

        subscription.filterPath := ?path(options!.filter!!);
      };

      let subscriptionInfo = unwrap(InfoModule.getSubscriptionInfo(caller, subscriberId, eventName));

      return { subscription; subscriptionInfo; prevSubscriptionInfo };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func unsubscribe(caller: Principal, subscriberId: Principal, eventName: Text, options: ?UnsubscribeOptions): UnsubscribeResponse {
      if (caller != deployer) Debug.trap(Errors.PERMISSION_DENIED);

      if (eventName.size() > Const.EVENT_NAME_LENGTH_LIMIT) Debug.trap(Errors.EVENT_NAME_LENGTH);

      let prevSubscriptionInfo = InfoModule.getSubscriptionInfo(caller, subscriberId, eventName);

      ignore do ?{
        let subscriber = Map.get(subscribers, phash, subscriberId)!;
        let subscriptionGroup = Map.get(subscriptions, thash, eventName)!;
        let subscription = Map.get(subscriptionGroup, phash, subscriberId)!;

        if (subscription.active) {
          subscription.active := false;
          subscriber.activeSubscriptions -%= 1;
        };

        if (options!.purge!) {
          Set.delete(subscriber.subscriptions, thash, eventName);
          Map.delete(subscriptionGroup, phash, subscriberId);

          if (Map.size(subscriptionGroup) == 0) Map.delete(subscriptions, thash, eventName);
        };
      };

      let subscriptionInfo = InfoModule.getSubscriptionInfo(caller, subscriberId, eventName);

      return { subscriptionInfo; prevSubscriptionInfo };
    };
  };
};
