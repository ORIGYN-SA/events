import Candy "mo:candy_0_1_9/types";
import Map "mo:map_8_0_0_alpha_5/Map";
import Set "mo:map_8_0_0_alpha_5/Set";

module {
  public type SubId = (Principal, Text);

  public type PubId = (Principal, Text);

  public type NumberOfAttempts = Nat8;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type Subscriber = {
    id: Principal;
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
    id: Principal;
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
    id: Nat;
    eventName: Text;
    payload: Candy.CandyValue;
    publisherId: Principal;
    createdAt: Nat64;
    var nextResendTime: Nat64;
    var numberOfAttempts: NumberOfAttempts;
    resendRequests: Set.Set<Principal>;
    subscribers: Map.Map<Principal, NumberOfAttempts>;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type State = {
    var eventId: Nat;
    var broadcastActive: Bool;
    var nextBroadcastTime: Nat64;
    admins: Set.Set<Principal>;
    subscribers: Map.Map<Principal, Subscriber>;
    subscriptions: Map.Map<SubId, Subscription>;
    publishers: Map.Map<Principal, Publisher>;
    publications: Map.Map<PubId, Publication>;
    events: Map.Map<Nat, Event>;
  };
};
