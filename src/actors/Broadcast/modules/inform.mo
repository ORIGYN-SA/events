import Const "../../../common/const";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import MigrationTypes "../../../migrations/types";
import Types "../../../common/types";
import Set "mo:map/Set";

module {
  let State = MigrationTypes.Current;

  let { nhash; thash; phash; lhash } = Map;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
