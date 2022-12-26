import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public func init(state: State.BroadcastState, deployer: Principal): {
    getEventInfo: (caller: Principal, publisherId: Principal, eventId: Nat) -> ?Types.SharedEvent;
  } = object {
    let { events } = state;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func getEventInfo(caller: Principal, publisherId: Principal, eventId: Nat): ?Types.SharedEvent {
      if (caller != deployer) Debug.trap(Errors.PERMISSION_DENIED);

      var result = null:?Types.SharedEvent;

      ignore do ?{
        let event = Map.get(events, nhash, eventId)!;

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
};
