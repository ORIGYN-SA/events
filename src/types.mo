import Candy "mo:candy/types";
import MigrationTypes "./migrations/types";

module {
  let StateTypes = MigrationTypes.Current;

  public type SubscriberActor = actor {
    handleEvent: (eventId: Nat, publisherId: Principal, eventName: Text, payload: Candy.CandyValue) -> ();
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type SharedSubscriber = {
    subscriberId: Principal;
    createdAt: Nat64;
    activeSubscriptions: Nat32;
    subscriptions: [Text];
  };

  public type SharedEvent = {
    eventId: Nat;
    eventName: Text;
    payload: Candy.CandyValue;
    publisherId: Principal;
    createdAt: Nat64;
    nextResendTime: Nat64;
    numberOfAttempts: Nat64;
    subscribers: [Principal];
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type SubscriptionOptions = [{
    #stopped: Bool;
    #skip: Nat32;
  }];

  public type UnsubscribeOptions = [{
    #purge;
  }];

  public type MissedEventOptions = [{
    #from: Nat64;
    #to: Nat64;
  }];

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type FetchSubscribersParams = {
    limit: Nat;
    offset: ?Nat;
    filters: ?{
      subscriberId: ?[Principal];
      subscriptions: ?[Text];
    };
  };

  public type FetchSubscribersResponse = {
    items: [SharedSubscriber];
    totalCount: Nat;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type FetchEventsFilters = {
    eventId: ?[Nat];
    eventName: ?[Text];
    publisherId: ?[Principal];
    numberOfAttempts: ?[Nat];
  };

  public type FetchEventsParams = {
    limit: Nat;
    offset: ?Nat;
    filters: ?FetchEventsFilters;
  };

  public type FetchEventsResponse = {
    items: [SharedEvent];
    totalCount: Nat;
  };
};
