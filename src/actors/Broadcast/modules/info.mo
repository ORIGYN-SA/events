import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import { n32hash; n64hash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type EventInfoResponse = ?Types.SharedEvent;

  public type EventInfoParams = (publisherId: Principal, eventId: Nat64);

  public type EventInfoFullParams = (caller: Principal, state: State.BroadcastState, params: EventInfoParams);

  public func getEventInfo((caller, state, (publisherId, eventId)): EventInfoFullParams): EventInfoResponse {
    if (caller != state.mainId) Debug.trap(Errors.PERMISSION_DENIED);

    let ?event = Map.get(state.events, n64hash, eventId) else return null;

    if (event.publisherId != publisherId) return null;

    return ?{
      id = event.id;
      eventName = event.eventName;
      publisherId = event.publisherId;
      payload = event.payload;
      createdAt = event.createdAt;
      nextBroadcastTime = event.nextBroadcastTime;
      numberOfAttempts = event.numberOfAttempts;
    };
  };
};
