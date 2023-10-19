import Candy "mo:candy_0_2_0/types";
import CandyUtils "mo:candy_utils_0_6_0/CandyUtils";
import Map "mo:map_8_1_0/Map";
import Set "mo:map_8_1_0/Set";
import Principal "mo:base/Principal";

module {
  public type EventType = {
    #Public;
    #System;
  };

  public type CanisterType = {
    #Broadcast;
    #Main;
    #PublishersIndex;
    #PublishersStore;
    #SubscribersIndex;
    #SubscribersStore;
  };

  public type CanisterStatus = {
    #Running;
    #Stopped;
    #Upgrading;
    #Upgraded;
    #UpgradeFailed;
  };

  public type Stats = {
    var numberOfEvents: Nat64;
    var numberOfNotifications: Nat64;
    var numberOfResendNotifications: Nat64;
    var numberOfRequestedNotifications: Nat64;
    var numberOfConfirmations: Nat64;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type Canister = {
    canisterId: Principal;
    canisterType: CanisterType;
    var status: CanisterStatus;
    var active: Bool;
    var heapSize: Nat;
    var balance: Nat;
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
    subscriberWhitelist: Set.Set<Principal>;
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
    publisherWhitelist: Set.Set<Principal>;
  };

  public type Event = {
    id: Nat64;
    eventName: Text;
    publisherId: Principal;
    eventType: EventType;
    payload: Candy.CandyShared;
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

  public type BroadcastGroup = Set.Set<Nat64>;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type BroadcastState = {
    mainId: Principal;
    publishersIndexId: Principal;
    subscribersIndexId: Principal;
    var subscribersStoreIds: Set.Set<Principal>;
    var active: Bool;
    var eventId: Nat64;
    var queueOverflowTime: Nat64;
    var broadcastVersion: Nat64;
    var broadcastQueued: Bool;
    var randomSeed: Nat32;
    events: Map.Map<Nat64, Event>;
    queuedEvents: Map.Map<Nat64, Nat32>;
    primaryBroadcastQueue: Map.Map<Nat32, BroadcastGroup>;
    secondaryBroadcastQueue: Map.Map<Nat32, BroadcastGroup>;
    primaryBroadcastGroups: Map.Map<Principal, Nat32>;
    secondaryBroadcastGroups: Map.Map<Principal, Nat32>;
    publicationStats: Map.Map<(Principal, Text), Stats>;
    subscriptionStats: Map.Map<(Principal, Text), Stats>;
    queueOverflows: Map.Map<Nat64, Nat64>;
  };

  public type MainState = {
    mainId: Principal;
    var publishersIndexId: Principal;
    var subscribersIndexId: Principal;
    var initialized: Bool;
    var broadcastSynced: Bool;
    var publishersStoreSynced: Bool;
    var subscribersStoreSynced: Bool;
    var queueOverflowCheckTime: Nat64;
    var broadcastVersion: Nat64;
    var status: CanisterStatus;
    admins: Set.Set<Principal>;
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
