import CandyUtils "mo:candy_utils/CandyUtils";
import Const "./const";
import Debug "mo:base/Debug";
import Map "mo:map/Map";
import MigrationTypes "../migrations/types";
import Option "mo:base/Option";
import Prim "mo:prim";
import Principal "mo:base/Principal";
import Set "mo:map/Set";
import State "../migrations/00-01-00-initial/types";

module {
  let State = MigrationTypes.Current;

  let { isNull; get = coalesce } = Option;

  let { path } = CandyUtils;

  let { nhash; thash; phash; lhash } = Map;

  let { time } = Prim;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  let SubscriberOptionsSize = 6;

  public type SubscriberOptions = [{
    #listeners: [Principal];
    #listenersAdd: [Principal];
    #listenersRemove: [Principal];
  }];

  let SubscriptionOptionsSize = 6;

  public type SubscriptionOptions = [{
    #stopped: Bool;
    #skip: Nat8;
    #filter: ?Text;
  }];

  let UnsubscribeOptionsSize = 1;

  public type UnsubscribeOptions = [{
    #purge;
  }];

  let MissedEventOptionsSize = 2;

  public type MissedEventOptions = [{
    #from: Nat64;
    #to: Nat64;
  }];

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.State, deployer: Principal): {
    registerSubscriber: (caller: Principal, options: SubscriberOptions) -> State.Subscriber;
    subscribe: (caller: Principal, eventName: Text, options: SubscriptionOptions) -> State.Subscription;
    unsubscribe: (caller: Principal, eventName: Text, options: UnsubscribeOptions) -> ();
    requestMissedEvents: (caller: Principal, eventName: Text, options: MissedEventOptions) -> ();
    confirmListener: (caller: Principal, subscriberId: Principal, allow: Bool) -> ();
    confirmEventProcessed: (caller: Principal, eventId: Nat) -> ();
  } = object {
    let { publications; subscribers; subscriptions; confirmedListeners; events } = state;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func registerSubscriber(caller: Principal, options: SubscriberOptions): State.Subscriber {
      if (options.size() > SubscriberOptionsSize) Debug.trap("Invalid number of options");

      let subscriber = Map.update<Principal, State.Subscriber>(subscribers, phash, caller, func(key, value) = coalesce(value, {
        id = caller;
        createdAt = time();
        var activeSubscriptions = 0:Nat8;
        listeners = Set.fromIter([caller].vals(), phash);
        confirmedListeners = Set.fromIter([caller].vals(), phash);
        subscriptions = Set.new(thash);
      }));

      for (option in options.vals()) switch (option) {
        case (#listeners(principalIds)) {
          if (principalIds.size() > Const.LISTENERS_LIMIT) Debug.trap("Listeners option length limit reached");

          Set.clear(subscriber.listeners);
          Set.clear(subscriber.confirmedListeners);

          for (principalId in principalIds.vals()) ignore do ?{
            Set.add(subscriber.listeners, phash, principalId);

            if (principalId == caller or Map.get(confirmedListeners, phash, principalId)! == caller) {
              Set.add(subscriber.confirmedListeners, phash, principalId);
            };
          };
        };

        case (#listenersAdd(principalIds)) {
          if (principalIds.size() > Const.LISTENERS_LIMIT) Debug.trap("ListenersAdd option length limit reached");

          for (principalId in principalIds.vals()) ignore do ?{
            Set.add(subscriber.listeners, phash, principalId);

            if (principalId == caller or Map.get(confirmedListeners, phash, principalId)! == caller) {
              Set.add(subscriber.confirmedListeners, phash, principalId);
            };
          };

          if (Set.size(subscriber.listeners) > Const.LISTENERS_LIMIT) Debug.trap("Listeners length limit reached");
        };

        case (#listenersRemove(principalIds)) {
          if (principalIds.size() > Const.LISTENERS_LIMIT) Debug.trap("ListenersRemove option length limit reached");

          for (principalId in principalIds.vals()) {
            Set.delete(subscriber.listeners, phash, principalId);
            Set.delete(subscriber.confirmedListeners, phash, principalId);
          };
        };
      };

      return subscriber;
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func subscribe(caller: Principal, eventName: Text, options: SubscriptionOptions): State.Subscription {
      if (eventName.size() > Const.EVENT_NAME_LENGTH_LIMIT) Debug.trap("Event name length limit reached");
      if (options.size() > SubscriptionOptionsSize) Debug.trap("Invalid number of options");

      let subscriber = registerSubscriber(caller, []);

      Set.add(subscriber.subscriptions, thash, eventName);

      if (Set.size(subscriber.subscriptions) > Const.SUBSCRIPTIONS_LIMIT) Debug.trap("Subscriptions limit reached");

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

        if (subscriber.activeSubscriptions > Const.ACTIVE_SUBSCRIPTIONS_LIMIT) Debug.trap("Active subscriptions limit reached");
      };

      for (option in options.vals()) switch (option) {
        case (#stopped(stopped)) subscription.stopped := stopped;

        case (#skip(skip)) subscription.skip := skip;

        case (#filter(filter)) {
          subscription.filter := filter;
          subscription.filterPath := do ?{ path(filter!) };
        };
      };

      return subscription;
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func unsubscribe(caller: Principal, eventName: Text, options: UnsubscribeOptions) {
      if (eventName.size() > Const.EVENT_NAME_LENGTH_LIMIT) Debug.trap("Event name length limit reached");
      if (options.size() > UnsubscribeOptionsSize) Debug.trap("Invalid number of options");

      ignore do ?{
        let subscriber = Map.get(subscribers, phash, caller)!;
        let subscriptionGroup = Map.get(subscriptions, thash, eventName)!;
        let subscription = Map.get(subscriptionGroup, phash, caller)!;

        if (subscription.active) {
          subscription.active := false;
          subscriber.activeSubscriptions -%= 1;
        };

        for (option in options.vals()) switch (option) {
          case (#purge) {
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
      };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func requestMissedEvents(caller: Principal, eventName: Text, options: MissedEventOptions) {
      if (eventName.size() > Const.EVENT_NAME_LENGTH_LIMIT) Debug.trap("Event name length limit reached");
      if (options.size() > MissedEventOptionsSize) Debug.trap("Invalid number of options");

      ignore do ?{
        let subscriptionGroup = Map.get(subscriptions, thash, eventName)!;
        let subscription = Map.get(subscriptionGroup, phash, caller)!;
        var from = 0:Nat64;
        var to = 0:Nat64 -% 1;

        for (option in options.vals()) switch (option) {
          case (#from(value)) from := value;
          case (#to(value)) to := value;
        };

        for (eventId in Set.keys(subscription.events)) ignore do ?{
          let event = Map.get(events, nhash, eventId)!;

          if (event.createdAt >= from and event.createdAt <= to) {
            Set.add(event.resendRequests, phash, caller);

            state.nextBroadcastTime := time();
          };
        };
      };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func confirmListener(caller: Principal, subscriberId: Principal, allow: Bool) {
      if (caller == subscriberId) Debug.trap("Can not confirm self as listener");

      if (allow) {
        let prevSubscriberId = Map.put(confirmedListeners, phash, caller, subscriberId);

        ignore do ?{
          if (subscriberId != prevSubscriberId!) {
            let prevSubscriber = Map.get(subscribers, phash, prevSubscriberId!)!;

            Set.delete(prevSubscriber.confirmedListeners, phash, caller);
          };
        };

        ignore do ?{
          if (isNull(prevSubscriberId) or subscriberId != prevSubscriberId!) {
            let subscriber = Map.get(subscribers, phash, subscriberId)!;

            if (Set.has(subscriber.listeners, phash, caller)) Set.add(subscriber.confirmedListeners, phash, caller);
          };
        };
      } else {
        ignore do ?{
          if (Map.get(confirmedListeners, phash, caller)! == subscriberId) {
            Map.delete(confirmedListeners, phash, caller);

            let subscriber = Map.get(subscribers, phash, subscriberId)!;

            Set.delete(subscriber.confirmedListeners, phash, caller);
          };
        };
      };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func confirmEventProcessed(caller: Principal, eventId: Nat) {
      ignore do ?{
        let event = Map.get(events, nhash, eventId)!;

        ignore Map.remove(event.subscribers, phash, caller)!;

        Set.delete(event.resendRequests, phash, caller);

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
    };
  };
};
