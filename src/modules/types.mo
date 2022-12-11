import Candy "mo:candy/types";

module {
  public type ListenerActor = actor {
    handleEvent: (eventId: Nat, publisherId: Principal, eventName: Text, payload: Candy.CandyValue) -> ();
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
    active: Bool;
    numberOfEvents: Nat64;
    numberOfNotifications: Nat64;
    numberOfResendNotifications: Nat64;
    numberOfRequestedNotifications: Nat64;
    numberOfConfirmations: Nat64;
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
    skip: Nat8;
    skipped: Nat8;
    active: Bool;
    stopped: Bool;
    filter: ?Text;
    numberOfEvents: Nat64;
    numberOfNotifications: Nat64;
    numberOfResendNotifications: Nat64;
    numberOfRequestedNotifications: Nat64;
    numberOfConfirmations: Nat64;
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
