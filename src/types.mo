import Candy "mo:candy/types";
import MigrationTypes "./migrations/types";
import Time "mo:base/Time";

module {
  let StateTypes = MigrationTypes.Current;

  public type SubscriberActor = actor {
    handleEvent: (canisterId: Principal, name: Text, payload: Candy.CandyValue) -> async ();
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type SharedSubscriber = {
    canisterId: Principal;
    createdAt: Time.Time;
    firstFailedEventTime: Time.Time;
    stale: Bool;
    eventNames: [Text];
  };

  public type FetchSubscribersFilters = {
    canisterId: ?[Principal];
    stale: ?[Bool];
    eventNames: ?[Text];
  };

  public type FetchSubscribersParams = {
    limit: Nat;
    offset: ?Nat;
    filters: ?FetchSubscribersFilters;
  };

  public type FetchSubscribersResponse = {
    items: [SharedSubscriber];
    totalCount: Nat;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type SharedEvent = {
    id: Nat;
    name: Text;
    payload: Candy.CandyValue;
    canisterId: Principal;
    createdAt: Time.Time;
    nextProcessingTime: Time.Time;
    numberOfDispatches: Nat;
    numberOfAttempts: Nat;
    stale: Bool;
    subscribers: [Principal];
  };

  public type FetchEventsFilters = {
    id: ?[Nat];
    name: ?[Text];
    canisterId: ?[Principal];
    stale: ?[Bool];
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
