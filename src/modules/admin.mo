import Array "mo:base/Array";
import Candy "mo:candy/types";
import Debug "mo:base/Debug";
import Errors "./errors";
import Map "mo:map/Map";
import MigrationTypes "../migrations/types";
import Option "mo:base/Option";
import Set "mo:map/Set";
import Types "./types";
import Utils "../utils/misc";

module {
  let State = MigrationTypes.Current;

  let { get = coalesce } = Option;

  let { arraySlice } = Utils;

  let { nhash; thash; phash; lhash } = Map;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type FetchSubscribersOptions = {
    limit: Nat;
    offset: ?Nat;
    filters: ?{
      subscriberId: ?[Principal];
      subscriptions: ?[Text];
    };
  };

  public type FetchSubscribersResponse = {
    items: [Types.SharedSubscriber];
    totalCount: Nat;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type FetchEventsOptions = {
    limit: Nat;
    offset: ?Nat;
    filters: ?{
      eventId: ?[Nat];
      eventName: ?[Text];
      publisherId: ?[Principal];
    };
  };

  public type FetchEventsResponse = {
    items: [Types.SharedEvent];
    totalCount: Nat;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.State, deployer: Principal): {
    fetchSubscribers: (caller: Principal, options: FetchSubscribersOptions) -> FetchSubscribersResponse;
    fetchEvents: (caller: Principal, options: FetchEventsOptions) -> FetchEventsResponse;
    getAdmins: (caller: Principal) -> [Principal];
    addAdmin: (caller: Principal, principalId: Principal) -> ();
    removeAdmin: (caller: Principal, principalId: Principal) -> ();
  } = object {
    let { admins; subscribers; events } = state;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    func isAdmin(principalId: Principal): Bool {
      return principalId == deployer or Set.has(admins, phash, principalId);
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func fetchSubscribers(caller: Principal, options: FetchSubscribersOptions): FetchSubscribersResponse {
      if (not isAdmin(caller)) Debug.trap(Errors.PERMISSION_DENIED);

      let subscriberId = do ?{ Set.fromIter(options.filters!.subscriberId!.vals(), phash) };
      let subscriptions = do ?{ Set.fromIter(options.filters!.subscriptions!.vals(), thash) };

      let subscribersArray = Map.toArrayMap<Principal, State.Subscriber, State.Subscriber>(subscribers, func(key, value) = ?value);

      let filteredSubscribers = Array.filter(subscribersArray, func(subscriber: State.Subscriber): Bool {
        ignore do ?{ if (not Set.has(subscriberId!, phash, subscriber.id)) return false };
        ignore do ?{ if (not Set.some<Text>(subscriptions!, func(item) = Set.has(subscriber.subscriptions, thash, item))) return false };

        return true;
      });

      let limitedSubscribers = arraySlice(filteredSubscribers, options.offset, ?(coalesce(options.offset, 0) + options.limit));

      let sharedSubscribers = Array.map(limitedSubscribers, func(subscriber: State.Subscriber): Types.SharedSubscriber = {
        id = subscriber.id;
        createdAt = subscriber.createdAt;
        activeSubscriptions = subscriber.activeSubscriptions;
        listeners = Set.toArray(subscriber.listeners);
        confirmedListeners = Set.toArray(subscriber.confirmedListeners);
        subscriptions = Set.toArray(subscriber.subscriptions);
      });

      return { items = sharedSubscribers; totalCount = filteredSubscribers.size() };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func fetchEvents(caller: Principal, options: FetchEventsOptions): FetchEventsResponse {
      if (not isAdmin(caller)) Debug.trap(Errors.PERMISSION_DENIED);

      let eventId = do ?{ Set.fromIter(options.filters!.eventId!.vals(), nhash) };
      let eventName = do ?{ Set.fromIter(options.filters!.eventName!.vals(), thash) };
      let publisherId = do ?{ Set.fromIter(options.filters!.publisherId!.vals(), phash) };

      let eventsArray = Map.toArrayMap<Nat, State.Event, State.Event>(events, func(key, value) = ?value);

      let filteredEvents = Array.filter(eventsArray, func(event: State.Event): Bool {
        ignore do ?{ if (not Set.has(eventId!, nhash, event.id)) return false };
        ignore do ?{ if (not Set.has(eventName!, thash, event.eventName)) return false };
        ignore do ?{ if (not Set.has(publisherId!, phash, event.publisherId)) return false };

        return true;
      });

      let limitedEvents = arraySlice(filteredEvents, options.offset, ?(coalesce(options.offset, 0) + options.limit));

      let sharedEvents = Array.map(limitedEvents, func(event: State.Event): Types.SharedEvent = {
        id = event.id;
        eventName = event.eventName;
        publisherId = event.publisherId;
        payload = event.payload;
        createdAt = event.createdAt;
        nextBroadcastTime = event.nextBroadcastTime;
        numberOfAttempts = event.numberOfAttempts;
      });

      return { items = sharedEvents; totalCount = filteredEvents.size() };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func getAdmins(caller: Principal): [Principal] {
      if (not isAdmin(caller)) Debug.trap(Errors.PERMISSION_DENIED);

      return Set.toArray(admins);
    };

    public func addAdmin(caller: Principal, principalId: Principal) {
      if (not isAdmin(caller)) Debug.trap(Errors.PERMISSION_DENIED);

      Set.add(admins, phash, principalId);
    };

    public func removeAdmin(caller: Principal, principalId: Principal) {
      if (not isAdmin(caller)) Debug.trap(Errors.PERMISSION_DENIED);

      Set.delete(admins, phash, principalId);
    };
  };
};
