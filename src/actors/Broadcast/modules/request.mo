import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Set "mo:map/Set";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type EventsRequest = {
    subscriberId: Principal;
    eventName: Text;
    from: ?Nat64;
    to: ?Nat64;
  };

  public type RequestEventsResponse = ();

  public type RequestEventsParams = (missedOnly: Bool, requests: [EventsRequest]);

  public type RequestEventsFullParams = (caller: Principal, state: State.BroadcastState, params: RequestEventsParams);

  public func requestEvents((caller, state, (missedOnly, requests)): RequestEventsFullParams): RequestEventsResponse {
    if (caller != state.mainId) Debug.trap(Errors.PERMISSION_DENIED);

    let eventNames = Set.fromIterMap<Text, EventsRequest>(requests.vals(), thash, func(item) = ?item.eventName);

    for (event in Map.vals(state.events)) if (Set.has(eventNames, thash, event.eventName)) {
      for ({ subscriberId; eventName; from; to } in requests.vals()) ignore do ?{
        if (
          event.eventName == eventName and
          (not missedOnly or Map.has(event.subscribers, phash, subscriberId)) and
          (from == null or event.createdAt < from!) and
          (to == null or event.createdAt > to!)
        ) {
          Set.add(event.eventRequests, phash, subscriberId);
          Set.add(state.broadcastQueue, nhash, event.id);
        };
      };
    };
  };
};
