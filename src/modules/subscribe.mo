import Cascade "./cascade";
import Candy "mo:candy/types";
import Const "./const";
import Debug "mo:base/Debug";
import Map "mo:map/Map";
import MigrationTypes "../migrations/types";
import Option "mo:base/Option";
import Prim "mo:prim";
import Principal "mo:base/Principal";
import Set "mo:map/Set";
import Utils "../utils/misc";

module {
  let State = MigrationTypes.Current;

  let { get = coalesce } = Option;

  let { pthash } = Utils;

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
    subscribe: (caller: Principal, eventName: Text, options: SubscriptionOptions) -> ();
    unsubscribe: (caller: Principal, eventName: Text, options: UnsubscribeOptions) -> ();
    requestMissedEvents: (caller: Principal, eventName: Text, options: MissedEventOptions) -> ();
    confirmEventProcessed: (caller: Principal, eventId: Nat) -> ();
  } = object {
    let { removeEventCascade } = Cascade.init(state, deployer);

    let { subscribers; subscriptions; events } = state;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func subscribe(caller: Principal, eventName: Text, options: SubscriptionOptions) {
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

      let subscription = Map.update<State.SubId, State.Subscription>(subscriptions, pthash, (caller, eventName), func(key, value) = coalesce(value, {
        eventName = eventName;
        subscriberId = caller;
        createdAt = time();
        var skip = 0:Nat8;
        var skipped = 0:Nat8;
        var active = false;
        var stopped = false;
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
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func unsubscribe(caller: Principal, eventName: Text, options: UnsubscribeOptions) {
      if (eventName.size() > Const.EVENT_NAME_LENGTH_LIMIT) Debug.trap("Event name length limit reached");
      if (options.size() > UnsubscribeOptionsSize) Debug.trap("Invalid number of options");

      ignore do ?{
        let subscriber = Map.get(subscribers, phash, caller)!;
        let subscription = Map.get(subscriptions, pthash, (caller, eventName))!;

        if (subscription.active) {
          subscription.active := false;
          subscriber.activeSubscriptions -%= 1;
        };

        for (option in options.vals()) switch (option) {
          case (#purge) {
            Set.delete(subscriber.subscriptions, thash, eventName);
            Map.delete(subscriptions, pthash, (caller, eventName));
          };
        };
      };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func requestMissedEvents(caller: Principal, eventName: Text, options: MissedEventOptions) {
      if (eventName.size() > Const.EVENT_NAME_LENGTH_LIMIT) Debug.trap("Event name length limit reached");
      if (options.size() > MissedEventOptionsSize) Debug.trap("Invalid number of options");

      ignore do ?{
        let subscription = Map.get(subscriptions, pthash, (caller, eventName))!;
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

        Map.delete(event.subscribers, phash, caller);

        if (Map.size(event.subscribers) == 0) removeEventCascade(eventId);
      };
    };
  };
};
