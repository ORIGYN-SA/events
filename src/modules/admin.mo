import Array "mo:base/Array";
import Cascade "./cascade";
import Candy "mo:candy/types";
import Debug "mo:base/Debug";
import Map "mo:map/Map";
import MigrationTypes "../migrations/types";
import Option "mo:base/Option";
import Set "mo:map/Set";
import Utils "../utils/misc";

module {
  let State = MigrationTypes.Current;

  let { get = coalesce } = Option;

  let { arraySlice } = Utils;

  let { nhash; thash; phash; lhash } = Map;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  type SharedSubscriber = {
    subscriberId: Principal;
    createdAt: Nat64;
    activeSubscriptions: Nat8;
    subscriptions: [Text];
  };

  type SharedEvent = {
    eventId: Nat;
    eventName: Text;
    payload: Candy.CandyValue;
    publisherId: Principal;
    createdAt: Nat64;
    nextBroadcastTime: Nat64;
    numberOfAttempts: Nat8;
    subscribers: [Principal];
  };

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

  public type FetchEventsParams = {
    limit: Nat;
    offset: ?Nat;
    filters: ?{
      eventId: ?[Nat];
      eventName: ?[Text];
      publisherId: ?[Principal];
    };
  };

  public type FetchEventsResponse = {
    items: [SharedEvent];
    totalCount: Nat;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.State, deployer: Principal): {
    fetchSubscribers: (caller: Principal, params: FetchSubscribersParams) -> FetchSubscribersResponse;
    fetchEvents: (caller: Principal, params: FetchEventsParams) -> FetchEventsResponse;
    removeSubscribers: (caller: Principal, subscriberIds: [Principal]) -> ();
    removeEvents: (caller: Principal, eventIds: [Nat]) -> ();
    getAdmins: (caller: Principal) -> [Principal];
    addAdmin: (caller: Principal, principalId: Principal) -> ();
    removeAdmin: (caller: Principal, principalId: Principal) -> ();
  } = object {
    let { removeEventCascade; removeSubscriberCascade } = Cascade.init(state, deployer);

    let { admins; subscribers; events } = state;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    func isAdmin(principalId: Principal): Bool {
      return principalId == deployer or Set.has(admins, phash, principalId);
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func fetchSubscribers(caller: Principal, params: FetchSubscribersParams): FetchSubscribersResponse {
      if (not isAdmin(caller)) Debug.trap("Not authorized");

      let subscriberId = do ?{ Set.fromIter(params.filters!.subscriberId!.vals(), phash) };
      let subscriptions = do ?{ Set.fromIter(params.filters!.subscriptions!.vals(), thash) };

      let subscribersArray = Map.toArray<Principal, State.Subscriber, State.Subscriber>(subscribers, func(key, value) = ?value);

      let filteredSubscribers = Array.filter(subscribersArray, func(subscriber: State.Subscriber): Bool {
        ignore do ?{ if (not Set.has(subscriberId!, phash, subscriber.id)) return false };
        ignore do ?{ if (not Set.some<Text>(subscriptions!, func(item) = Set.has(subscriber.subscriptions, thash, item))) return false };

        return true;
      });

      let limitedSubscribers = arraySlice(filteredSubscribers, params.offset, ?(coalesce(params.offset, 0) + params.limit));

      let sharedSubscribers = Array.map(limitedSubscribers, func(subscriber: State.Subscriber): SharedSubscriber {{
        subscriberId = subscriber.id;
        createdAt = subscriber.createdAt;
        activeSubscriptions = subscriber.activeSubscriptions;
        subscriptions = Set.toArray<Text, Text>(subscriber.subscriptions, func(key) = ?key);
      }});

      return { items = sharedSubscribers; totalCount = filteredSubscribers.size() };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func fetchEvents(caller: Principal, params: FetchEventsParams): FetchEventsResponse {
      if (not isAdmin(caller)) Debug.trap("Not authorized");

      let eventId = do ?{ Set.fromIter(params.filters!.eventId!.vals(), nhash) };
      let eventName = do ?{ Set.fromIter(params.filters!.eventName!.vals(), thash) };
      let publisherId = do ?{ Set.fromIter(params.filters!.publisherId!.vals(), phash) };

      let eventsArray = Map.toArray<Nat, State.Event, State.Event>(events, func(key, value) = ?value);

      let filteredEvents = Array.filter(eventsArray, func(event: State.Event): Bool {
        ignore do ?{ if (not Set.has(eventId!, nhash, event.id)) return false };
        ignore do ?{ if (not Set.has(eventName!, thash, event.eventName)) return false };
        ignore do ?{ if (not Set.has(publisherId!, phash, event.publisherId)) return false };

        return true;
      });

      let limitedEvents = arraySlice(filteredEvents, params.offset, ?(coalesce(params.offset, 0) + params.limit));

      let sharedEvents = Array.map(limitedEvents, func(event: State.Event): SharedEvent {{
        eventId = event.id;
        eventName = event.eventName;
        payload = event.payload;
        publisherId = event.publisherId;
        createdAt = event.createdAt;
        nextBroadcastTime = event.nextBroadcastTime;
        numberOfAttempts = event.numberOfAttempts;
        subscribers = Map.toArray<Principal, Nat8, Principal>(event.subscribers, func(key, value) = ?key);
      }});

      return { items = sharedEvents; totalCount = filteredEvents.size() };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func removeSubscribers(caller: Principal, subscriberIds: [Principal]) {
      if (not isAdmin(caller)) Debug.trap("Not authorized");

      for (subscriberId in subscriberIds.vals()) removeSubscriberCascade(subscriberId);
    };

    public func removeEvents(caller: Principal, eventIds: [Nat]) {
      if (not isAdmin(caller)) Debug.trap("Not authorized");

      for (eventId in eventIds.vals()) removeEventCascade(eventId);
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func getAdmins(caller: Principal): [Principal] {
      if (not isAdmin(caller)) Debug.trap("Not authorized");

      return Set.toArray<Principal, Principal>(admins, func(key) = ?key);
    };

    public func addAdmin(caller: Principal, principalId: Principal) {
      if (not isAdmin(caller)) Debug.trap("Not authorized");

      Set.add(admins, phash, principalId);
    };

    public func removeAdmin(caller: Principal, principalId: Principal) {
      if (not isAdmin(caller)) Debug.trap("Not authorized");

      Set.delete(admins, phash, principalId);
    };
  };
};
