import Candy "mo:candy_0_1_9/types";
import Map "mo:map_8_0_0_alpha_5/Map";
import Set "mo:map_8_0_0_alpha_5/Set";

module {
  public type PT = (Principal, Text);

  public type Subscriber = {
    subscriberId: Principal;
    createdAt: Nat64;
    var activeSubscriptions: Nat8;
    subscriptions: Set.Set<Text>;
  };

  public type Subscription = {
    eventName: Text;
    subscriberId: Principal;
    createdAt: Nat64;
    var skip: Nat8;
    var skipped: Nat8;
    var active: Bool;
    var stopped: Bool;
    events: Set.Set<Nat>;
  };

  public type Publisher = {
    publisherId: Principal;
    createdAt: Nat64;
    var activePublications: Nat8;
    publications: Set.Set<Text>;
  };

  public type Publication = {
    eventName: Text;
    publisherId: Principal;
    var active: Bool;
    whitelist: Set.Set<Principal>;
  };

  public type Event = {
    eventId: Nat;
    eventName: Text;
    payload: Candy.CandyValue;
    publisherId: Principal;
    createdAt: Nat64;
    var nextResendTime: Nat64;
    var numberOfAttempts: Nat8;
    subscribers: Set.Set<Principal>;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type State = {
    var eventId: Nat;
    var nextBroadcastTime: Nat64;
    admins: Set.Set<Principal>;
    subscribers: Map.Map<Principal, Subscriber>;
    subscriptions: Map.Map<PT, Subscription>;
    publishers: Map.Map<Principal, Publisher>;
    publications: Map.Map<PT, Publication>;
    events: Map.Map<Nat, Event>;
  };
};
