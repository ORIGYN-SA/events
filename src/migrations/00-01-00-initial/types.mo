import Candy "mo:candy/types";
import CurrentState "./state";

module {
  public let State = CurrentState;

  public type ListenerActor = actor {
    handleEvent: (eventId: Nat, publisherId: Principal, eventName: Text, payload: Candy.CandyValue) -> async ();
  };

  public type InternetComputerActor = actor {
    start_canister: ({ canister_id: Principal }) -> async ();
    stop_canister: ({ canister_id: Principal }) -> async ();
    delete_canister: ({ canister_id: Principal }) -> async ();
    deposit_cycles: ({ canister_id: Principal }) -> async ();
  };

  public type SharedCanister = {
    canisterId: Principal;
    canisterType: State.CanisterType;
    active: Bool;
    heapSize: Nat;
    balance: Nat;
  };

  public type SharedStats = {
    numberOfEvents: Nat64;
    numberOfNotifications: Nat64;
    numberOfResendNotifications: Nat64;
    numberOfRequestedNotifications: Nat64;
    numberOfConfirmations: Nat64;
  };

  public type SharedPublisher = {
    id: Principal;
    createdAt: Nat64;
    activePublications: Nat8;
    publications: [Text];
  };

  public type SharedPublication = {
    eventName: Text;
    publisherId: Principal;
    createdAt: Nat64;
    stats: SharedStats;
    active: Bool;
    whitelist: [Principal];
  };

  public type SharedSubscriber = {
    id: Principal;
    createdAt: Nat64;
    activeSubscriptions: Nat8;
    listeners: [Principal];
    confirmedListeners: [Principal];
    subscriptions: [Text];
  };

  public type SharedSubscription = {
    eventName: Text;
    subscriberId: Principal;
    createdAt: Nat64;
    stats: SharedStats;
    rate: Nat32;
    active: Bool;
    stopped: Bool;
    filter: ?Text;
  };

  public type SharedEvent = {
    id: Nat;
    eventName: Text;
    publisherId: Principal;
    payload: Candy.CandyValue;
    createdAt: Nat64;
    nextBroadcastTime: Nat64;
    numberOfAttempts: Nat8;
  };
};
