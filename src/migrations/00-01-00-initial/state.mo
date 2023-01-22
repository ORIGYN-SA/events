import Candy "mo:candy_0_1_9/types";
import CandyUtils "mo:candy_utils_0_2_1/CandyUtils";
import Map "mo:map_8_0_0_rc_2/Map";
import Set "mo:map_8_0_0_rc_2/Set";
import Principal "mo:base/Principal";

module {
  public type CanisterType = {
    #Broadcast;
    #Main;
    #PublishersIndex;
    #PublishersStore;
    #SubscribersIndex;
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
    var rate: Nat32;
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
    var lastSubscriberId: ?Principal;
    var lastSubscribersStoreId: ?Principal;
    sendRequests: Set.Set<Principal>;
    subscribers: Set.Set<Principal>;
  };

  public type PublicationGroup = Map.Map<Principal, Publication>;

  public type SubscriptionGroup = Map.Map<Principal, Subscription>;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type BroadcastState = {
    mainId: Principal;
    publishersIndexId: Principal;
    subscribersIndexId: Principal;
    var subscribersStoreIds: Set.Set<Principal>;
    var eventId: Nat;
    var maxQueueSize: Nat32;
    var broadcastIndex: Nat64;
    var broadcastTimerId: Nat;
    var randomSeed: Nat32;
    events: Map.Map<Nat, Event>;
    broadcastQueue: Set.Set<Nat>;
    publicationStats: Map.Map<(Principal, Text), Stats>;
    subscriptionStats: Map.Map<(Principal, Text), Stats>;
  };

  public type MainState = {
    var initialized: Bool;
    var broadcastIndex: Nat64;
    canisters: Map.Map<Principal, Canister>;
  };

  public type PublishersIndexState = {
    mainId: Principal;
    var publishersStoreId: ?Principal;
    broadcastIds: Set.Set<Principal>;
    publishersLocation: Map.Map<Principal, Principal>;
  };

  public type PublishersStoreState = {
    mainId: Principal;
    publishersIndexId: Principal;
    broadcastIds: Set.Set<Principal>;
    publishers: Map.Map<Principal, Publisher>;
    publications: Map.Map<Text, PublicationGroup>;
  };

  public type SubscribersIndexState = {
    mainId: Principal;
    var subscribersStoreId: ?Principal;
    broadcastIds: Set.Set<Principal>;
    subscribersLocation: Map.Map<Principal, Principal>;
  };

  public type SubscribersStoreState = {
    mainId: Principal;
    subscribersIndexId: Principal;
    broadcastIds: Set.Set<Principal>;
    subscribers: Map.Map<Principal, Subscriber>;
    subscriptions: Map.Map<Text, SubscriptionGroup>;
  };

  public type State = {
    #Broadcast: BroadcastState;
    #Main: MainState;
    #PublishersIndex: PublishersIndexState;
    #PublishersStore: PublishersStoreState;
    #SubscribersIndex: SubscribersIndexState;
    #SubscribersStore: SubscribersStoreState;
  };
};
