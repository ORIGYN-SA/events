import Candy "mo:candy_0_1_9/types";
import CandyUtils "mo:candy_utils_0_2_0/CandyUtils";
import Map "mo:map_8_0_0_alpha_5/Map";
import Set "mo:map_8_0_0_alpha_5/Set";

module {
  public type Publisher = {
    id: Principal;
    createdAt: Nat64;
    var activePublications: Nat8;
    publications: Set.Set<Text>;
  };

  public type Publication = {
    eventName: Text;
    publisherId: Principal;
    createdAt: Nat64;
    var active: Bool;
    var numberOfEvents: Nat64;
    var numberOfNotifications: Nat64;
    var numberOfResendNotifications: Nat64;
    var numberOfRequestedNotifications: Nat64;
    var numberOfConfirmations: Nat64;
    whitelist: Set.Set<Principal>;
  };

  public type PublicationStable = {
    eventName: Text;
    publisherId: Principal;
    createdAt: Nat64;
    active: Bool;
    numberOfEvents: Nat64;
    numberOfNotifications: Nat64;
    numberOfResendNotifications: Nat64;
    numberOfRequestedNotifications: Nat64;
    numberOfConfirmations: Nat64;
    whitelist: [Principal];
  };

  public type Subscriber = {
    id: Principal;
    createdAt: Nat64;
    var activeSubscriptions: Nat8;
    listeners: Set.Set<Principal>;
    confirmedListeners: Set.Set<Principal>;
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
    var filter: ?Text;
    var filterPath: ?CandyUtils.Path;
    var numberOfEvents: Nat64;
    var numberOfNotifications: Nat64;
    var numberOfResendNotifications: Nat64;
    var numberOfRequestedNotifications: Nat64;
    var numberOfConfirmations: Nat64;
    events: Set.Set<Nat>;
  };


  public type SubscriptionStable = {
    eventName: Text;
    subscriberId: Principal;
    createdAt: Nat64;
    skip: Nat8;
    active: Bool;
    stopped: Bool;
    filter: ?Text;
    numberOfEvents: Nat64;
    numberOfNotifications: Nat64;
    numberOfResendNotifications: Nat64;
    numberOfRequestedNotifications: Nat64;
    numberOfConfirmations: Nat64;
    events: [Nat];
  };

  public type Event = {
    id: Nat;
    eventName: Text;
    publisherId: Principal;
    payload: Candy.CandyValue;
    createdAt: Nat64;
    var nextBroadcastTime: Nat64;
    var numberOfAttempts: Nat8;
    resendRequests: Set.Set<Principal>;
    subscribers: Map.Map<Principal, Nat8>;
  };

  public type PublicationGroup = Map.Map<Principal, Publication>;

  public type SubscriptionGroup = Map.Map<Principal, Subscription>;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type State = {
    var eventId: Nat;
    var broadcastActive: Bool;
    var nextBroadcastTime: Nat64;
    admins: Set.Set<Principal>;
    publishers: Map.Map<Principal, Publisher>;
    publications: Map.Map<Text, PublicationGroup>;
    subscribers: Map.Map<Principal, Subscriber>;
    subscriptions: Map.Map<Text, SubscriptionGroup>;
    confirmedListeners: Map.Map<Principal, Principal>;
    events: Map.Map<Nat, Event>;
  };
};
