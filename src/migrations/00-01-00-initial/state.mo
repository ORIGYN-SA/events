import Candy "mo:candy_0_1_9/types";
import CandyUtils "mo:candy_utils_0_2_1/CandyUtils";
import Map "mo:map_8_0_0_rc_2/Map";
import Set "mo:map_8_0_0_rc_2/Set";

module {
  public type CanisterType = {
    #Broadcast;
    #Main;
    #PublishersStore;
    #SubscribersStore;
  };

  public type Canister = {
    canisterId: Principal;
    canisterType: CanisterType;
    var heapSize: Nat;
    var balance: Nat;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type Stats = {
    var numberOfEvents: Nat64;
    var numberOfNotifications: Nat64;
    var numberOfResendNotifications: Nat64;
    var numberOfRequestedNotifications: Nat64;
    var numberOfConfirmations: Nat64;
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
    createdAt: Nat64;
    stats: Stats;
    var active: Bool;
    whitelist: Set.Set<Principal>;
  };

  public type Subscriber = {
    id: Principal;
    createdAt: Nat64;
    var activeSubscriptions: Nat8;
    var listeners: Set.Set<Principal>;
    var confirmedListeners: [Principal];
    subscriptions: Set.Set<Text>;
  };

  public type Subscription = {
    eventName: Text;
    subscriberId: Principal;
    createdAt: Nat64;
    stats: Stats;
    var rate: Nat8;
    var active: Bool;
    var stopped: Bool;
    var filter: ?Text;
    var filterPath: ?CandyUtils.Path;
  };

  public type Event = {
    id: Nat;
    eventName: Text;
    publisherId: Principal;
    payload: Candy.CandyValue;
    createdAt: Nat64;
    var nextBroadcastTime: Nat64;
    var numberOfAttempts: Nat8;
    eventRequests: Set.Set<Principal>;
    subscribers: Map.Map<Principal, Nat8>;
  };

  public type PublicationGroup = Map.Map<Principal, Publication>;

  public type SubscriptionGroup = Map.Map<Principal, Subscription>;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type BroadcastState = {
    var eventId: Nat;
    var broadcastActive: Bool;
    var maxQueueSize: Nat32;
    canisters: Map.Map<Principal, Canister>;
    events: Map.Map<Nat, Event>;
    broadcastQueue: Set.Set<Nat>;
    publicationStats: Map.Map<(Principal, Text), Stats>;
    subscriptionStats: Map.Map<(Principal, Text), Stats>;
  };

  public type MainState = {
    canisters: Map.Map<Principal, Canister>;
  };

  public type PublishersStoreState = {
    canisters: Map.Map<Principal, Canister>;
    publishers: Map.Map<Principal, Publisher>;
    publications: Map.Map<Text, PublicationGroup>;
  };

  public type SubscribersStoreState = {
    canisters: Map.Map<Principal, Canister>;
    subscribers: Map.Map<Principal, Subscriber>;
    subscriptions: Map.Map<Text, SubscriptionGroup>;
  };

  public type State = {
    #Broadcast: BroadcastState;
    #Main: MainState;
    #PublishersStore: PublishersStoreState;
    #SubscribersStore: SubscribersStoreState;
  };
};
