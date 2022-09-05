import Candy "mo:candy_0_1_9/types";
import Map "mo:map_8_0_0_alpha_5/Map";
import Set "mo:map_8_0_0_alpha_5/Set";

module {
  public type SubId = (Principal, Text);

  public type Subscription = {
    eventName: Text;
    subscriberId: Principal;
    createdAt: Nat64;
    var skip: Nat32;
    var skipped: Nat32;
    var active: Bool;
    var stopped: Bool;
    events: Set.Set<Nat>;
  };

  public type Subscriber = {
    subscriberId: Principal;
    createdAt: Nat64;
    var activeSubscriptions: Nat32;
    subscriptions: Set.Set<Text>;
  };

  public type Event = {
    eventId: Nat;
    eventName: Text;
    payload: Candy.CandyValue;
    publisherId: Principal;
    createdAt: Nat64;
    var nextResendTime: Nat64;
    var numberOfAttempts: Nat64;
    subscribers: Set.Set<Principal>;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type State = {
    var eventId: Nat;
    var nextBroadcastTime: Nat64;
    admins: Set.Set<Principal>;
    subscribers: Map.Map<Principal, Subscriber>;
    subscriptions: Map.Map<SubId, Subscription>;
    events: Map.Map<Nat, Event>;
  };
};
