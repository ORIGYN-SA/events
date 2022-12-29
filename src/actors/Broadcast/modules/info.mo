import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type EventInfoResponse = ?Types.SharedEvent;

  public type EventInfoParams = (publisherId: Principal, eventId: Nat);

  public type EventInfoFullParams = (caller: Principal, state: State.BroadcastState, params: EventInfoParams);

  public func getEventInfo((caller, state, (publisherId, eventId)): EventInfoFullParams): EventInfoResponse {
    if (caller != state.mainId) Debug.trap(Errors.PERMISSION_DENIED);

    var result = null:?Types.SharedEvent;

    ignore do ?{
      let event = Map.get(state.events, nhash, eventId)!;

      if (event.publisherId == publisherId) result := ?{
        id = event.id;
        eventName = event.eventName;
        publisherId = event.publisherId;
        payload = event.payload;
        createdAt = event.createdAt;
        nextBroadcastTime = event.nextBroadcastTime;
        numberOfAttempts = event.numberOfAttempts;
      };
    };

    return result;
  };
};
