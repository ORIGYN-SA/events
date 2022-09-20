import Candy "mo:candy/types";
import Cascade "./cascade";
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

  let { get = coalesce } = Option;

  let { nhash; thash; phash; lhash } = Map;

  let { time } = Prim;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type SubscriberActor = actor {
    handleEvent: (eventId: Nat, publisherId: Principal, eventName: Text, payload: Candy.CandyValue) -> ();
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  let SubscriptionOptionsSize = 2;

  public type SubscriptionOptions = [{
    #stopped: Bool;
    #skip: Nat8;
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
    subscribe: (caller: Principal, eventName: Text, options: SubscriptionOptions) -> State.Subscription;
    unsubscribe: (caller: Principal, eventName: Text, options: UnsubscribeOptions) -> ();
    requestMissedEvents: (caller: Principal, eventName: Text, options: MissedEventOptions) -> ();
    confirmEventProcessed: (caller: Principal, eventId: Nat) -> ();
  } = object {
    let { removeEventCascade } = Cascade.init(state, deployer);

    let { publications; subscribers; subscriptions; events } = state;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func subscribe(caller: Principal, eventName: Text, options: SubscriptionOptions): State.Subscription {
      if (eventName.size() > Const.EVENT_NAME_LENGTH_LIMIT) Debug.trap("Event name length limit reached");
      if (options.size() > SubscriptionOptionsSize) Debug.trap("Invalid number of options");

      let subscriber = Map.update<Principal, State.Subscriber>(subscribers, phash, caller, func(key, value) = coalesce(value, {
        id = caller;
        createdAt = time();
        var activeSubscriptions = 0:Nat8;
        subscriptions = Set.new(thash);
      }));

      Set.add(subscriber.subscriptions, thash, eventName);

      if (Set.size(subscriber.subscriptions) > Const.SUBSCRIPTIONS_LIMIT) Debug.trap("Subscriptions limit reached");

      let subscriptionGroup = Map.update<Text, Map.Map<Principal, State.Subscription>>(subscriptions, thash, eventName, func(key, value) {
        return coalesce<Map.Map<Principal, State.Subscription>>(value, Map.new(phash));
      });

      let subscription = Map.update<Principal, State.Subscription>(subscriptionGroup, phash, caller, func(key, value) = coalesce(value, {
        eventName = eventName;
        subscriberId = caller;
        createdAt = time();
        var skip = 0:Nat8;
        var skipped = 0:Nat8;
        var active = false;
        var stopped = false;
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

    public func confirmEventProcessed(caller: Principal, eventId: Nat) {
      ignore do ?{
        let event = Map.get(events, nhash, eventId)!;

        ignore Map.remove(event.subscribers, phash, caller)!;

        if (Map.size(event.subscribers) == 0) removeEventCascade(eventId);

        ignore do ?{
          let publicationGroup = Map.get(publications, thash, event.eventName)!;
          let publication = Map.get(publicationGroup, phash, event.publisherId)!;

          publication.numberOfConfirmations +%= 1;
        };

        ignore do ?{
          let subscriptionGroup = Map.get(subscriptions, thash, event.eventName)!;
          let subscription = Map.get(subscriptionGroup, phash, caller)!;

          subscription.numberOfConfirmations +%= 1;
        };
      };
    };
  };
};
