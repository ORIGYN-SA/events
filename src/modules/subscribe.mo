import CandyUtils "mo:candy_utils/CandyUtils";
import Const "./const";
import Debug "mo:base/Debug";
import Errors "./errors";
import Info "./info";
import Map "mo:map/Map";
import MigrationTypes "../migrations/types";
import Option "mo:base/Option";
import Prim "mo:prim";
import Principal "mo:base/Principal";
import Set "mo:map/Set";
import State "../migrations/00-01-00-initial/types";
import Types "./types";
import Utils "../utils/misc";

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
    skip: ?Nat8;
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

  public type MissedEventsOptions = {
    from: ?Nat64;
    to: ?Nat64;
  };

  public type MissedEventsResponse = {
    count: Nat32;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type ConfirmEventResponse = {
    confirmed: Bool;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.State, deployer: Principal): {
    registerSubscriber: (caller: Principal, options: ?SubscriberOptions) -> SubscriberResponse;
    subscribe: (caller: Principal, eventName: Text, options: ?SubscriptionOptions) -> SubscriptionResponse;
    unsubscribe: (caller: Principal, eventName: Text, options: ?UnsubscribeOptions) -> UnsubscribeResponse;
    requestMissedEvents: (caller: Principal, eventName: Text, options: ?MissedEventsOptions) -> MissedEventsResponse;
    confirmEventProcessed: (caller: Principal, eventId: Nat) -> ConfirmEventResponse;
  } = object {
    let { publications; subscribers; subscriptions; confirmedListeners; events } = state;

    let InfoModule = Info.init(state, deployer);

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func registerSubscriber(caller: Principal, options: ?SubscriberOptions): SubscriberResponse {
      let prevSubscriberInfo = InfoModule.getSubscriberInfo(caller, options);

      let subscriber = Map.update<Principal, State.Subscriber>(subscribers, phash, caller, func(key, value) = coalesce(value, {
        id = caller;
        createdAt = time();
        var activeSubscriptions = 0:Nat8;
        listeners = Set.fromIter([caller].vals(), phash);
        confirmedListeners = Set.fromIter([caller].vals(), phash);
        subscriptions = Set.new(thash);
      }));

      ignore do ?{
        if (options!.listeners!.size() > Const.LISTENERS_LIMIT) Debug.trap(Errors.LISTENERS_REPLACE_LENGTH);

        Set.clear(subscriber.listeners);
        Set.clear(subscriber.confirmedListeners);

        for (principalId in options!.listeners!.vals()) ignore do ?{
          Set.add(subscriber.listeners, phash, principalId);

          if (principalId == caller or Map.get(confirmedListeners, phash, principalId)! == caller) {
            Set.add(subscriber.confirmedListeners, phash, principalId);
          };
        };
      };

      ignore do ?{
        if (options!.listenersAdd!.size() > Const.LISTENERS_LIMIT) Debug.trap(Errors.LISTENERS_ADD_LENGTH);

        for (principalId in options!.listenersAdd!.vals()) ignore do ?{
          Set.add(subscriber.listeners, phash, principalId);

          if (principalId == caller or Map.get(confirmedListeners, phash, principalId)! == caller) {
            Set.add(subscriber.confirmedListeners, phash, principalId);
          };
        };

        if (Set.size(subscriber.listeners) > Const.LISTENERS_LIMIT) Debug.trap(Errors.LISTENERS_LENGTH);
      };

      ignore do ?{
        if (options!.listenersRemove!.size() > Const.LISTENERS_LIMIT) Debug.trap(Errors.LISTENERS_REMOVE_LENGTH);

        for (principalId in options!.listenersRemove!.vals()) {
          Set.delete(subscriber.listeners, phash, principalId);
          Set.delete(subscriber.confirmedListeners, phash, principalId);
        };
      };

      let subscriberInfo = unwrap(InfoModule.getSubscriberInfo(caller, options));

      return { subscriber; subscriberInfo; prevSubscriberInfo };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func subscribe(caller: Principal, eventName: Text, options: ?SubscriptionOptions): SubscriptionResponse {
      let prevSubscriptionInfo = InfoModule.getSubscriptionInfo(caller, eventName);

      if (eventName.size() > Const.EVENT_NAME_LENGTH_LIMIT) Debug.trap(Errors.EVENT_NAME_LENGTH);

      let { subscriber } = registerSubscriber(caller, null);

      Set.add(subscriber.subscriptions, thash, eventName);

      if (Set.size(subscriber.subscriptions) > Const.SUBSCRIPTIONS_LIMIT) Debug.trap(Errors.SUBSCRIPTIONS_LENGTH);

      let subscriptionGroup = Map.update<Text, State.SubscriptionGroup>(subscriptions, thash, eventName, func(key, value) {
        return coalesce<State.SubscriptionGroup>(value, Map.new(phash));
      });

      let subscription = Map.update<Principal, State.Subscription>(subscriptionGroup, phash, caller, func(key, value) = coalesce(value, {
        eventName = eventName;
        subscriberId = caller;
        createdAt = time();
        var skip = 0:Nat8;
        var skipped = 0:Nat8;
        var active = false;
        var stopped = false;
        var filter = null:?Text;
        var filterPath = null:?CandyUtils.Path;
        var numberOfEvents = 0:Nat64;
        var numberOfNotifications = 0:Nat64;
        var numberOfResendNotifications = 0:Nat64;
        var numberOfRequestedNotifications = 0:Nat64;
        var numberOfConfirmations = 0:Nat64;
        events = Set.new(nhash);
      }));

      if (not subscription.active) {
        subscription.active := true;
        subscriber.activeSubscriptions +%= 1;

        if (subscriber.activeSubscriptions > Const.ACTIVE_SUBSCRIPTIONS_LIMIT) Debug.trap(Errors.ACTIVE_SUBSCRIPTIONS_LENGTH);
      };

      ignore do ?{ subscription.stopped := options!.stopped! };

      ignore do ?{ subscription.skip := options!.skip! };

      ignore do ?{
        subscription.filter := options!.filter!;
        subscription.filterPath := null;
        subscription.filterPath := ?path(options!.filter!!);
      };

      let subscriptionInfo = unwrap(InfoModule.getSubscriptionInfo(caller, eventName));

      return { subscription; subscriptionInfo; prevSubscriptionInfo };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func unsubscribe(caller: Principal, eventName: Text, options: ?UnsubscribeOptions): UnsubscribeResponse {
      if (eventName.size() > Const.EVENT_NAME_LENGTH_LIMIT) Debug.trap(Errors.EVENT_NAME_LENGTH);

      let prevSubscriptionInfo = InfoModule.getSubscriptionInfo(caller, eventName);

      ignore do ?{
        let subscriber = Map.get(subscribers, phash, caller)!;
        let subscriptionGroup = Map.get(subscriptions, thash, eventName)!;
        let subscription = Map.get(subscriptionGroup, phash, caller)!;

        if (subscription.active) {
          subscription.active := false;
          subscriber.activeSubscriptions -%= 1;
        };

        if (options!.purge!) {
          Set.delete(subscriber.subscriptions, thash, eventName);
          Map.delete(subscriptionGroup, phash, caller);

          for (eventId in Set.keys(subscription.events)) ignore do ?{
            let event = Map.get(events, nhash, eventId)!;

            Set.delete(event.resendRequests, phash, caller);
            Map.delete(event.subscribers, phash, caller);

            if (Map.size(event.subscribers) == 0) Map.delete(events, nhash, eventId);
          };

          if (Map.size(subscriptionGroup) == 0) Map.delete(subscriptions, thash, eventName);
        };
      };

      let subscriptionInfo = InfoModule.getSubscriptionInfo(caller, eventName);

      return { subscriptionInfo; prevSubscriptionInfo };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func requestMissedEvents(caller: Principal, eventName: Text, options: ?MissedEventsOptions): MissedEventsResponse {
      if (eventName.size() > Const.EVENT_NAME_LENGTH_LIMIT) Debug.trap(Errors.EVENT_NAME_LENGTH);

      var count = 0:Nat32;

      ignore do ?{
        let subscriptionGroup = Map.get(subscriptions, thash, eventName)!;
        let subscription = Map.get(subscriptionGroup, phash, caller)!;

        for (eventId in Set.keys(subscription.events)) label iteration ignore do ?{
          let event = Map.get(events, nhash, eventId)!;

          ignore do ?{ if (event.createdAt < options!.from!) break iteration };
          ignore do ?{ if (event.createdAt > options!.to!) break iteration };

          count +%= 1;

          Set.add(event.resendRequests, phash, caller);

          state.nextBroadcastTime := time();
        };
      };

      return { count };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func confirmEventProcessed(caller: Principal, eventId: Nat): ConfirmEventResponse {
      var confirmed = false;

      ignore do ?{
        let event = Map.get(events, nhash, eventId)!;

        ignore Map.remove(event.subscribers, phash, caller)!;

        Set.delete(event.resendRequests, phash, caller);

        confirmed := true;

        ignore do ?{
          let publicationGroup = Map.get(publications, thash, event.eventName)!;
          let publication = Map.get(publicationGroup, phash, event.publisherId)!;

          publication.numberOfConfirmations +%= 1;
        };

        ignore do ?{
          let subscriptionGroup = Map.get(subscriptions, thash, event.eventName)!;
          let subscription = Map.get(subscriptionGroup, phash, caller)!;

          subscription.numberOfConfirmations +%= 1;

          Set.delete(subscription.events, nhash, eventId);
        };

        if (Map.size(event.subscribers) == 0) Map.delete(events, nhash, eventId);
      };

      return { confirmed };
    };
  };
};
