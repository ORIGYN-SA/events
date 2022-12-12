import Candy "mo:candy/types";
import Const "../../../common/const";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Inform "./inform";
import Map "mo:map/Map";
import MigrationTypes "../../../migrations/types";
import Prim "mo:prim";
import Set "mo:map/Set";
import Types "../../../common/types";
import Utils "../../../utils/misc";

module {
  let State = MigrationTypes.Current;

  let { unwrap } = Utils;

  let { nhash; thash; phash; lhash } = Map;

  let { time } = Prim;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type PublishResponse = {
    eventInfo: Types.SharedEvent;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.BroadcastState, deployer: Principal): {
    publish: (caller: Principal, eventName: Text, payload: Candy.CandyValue) -> PublishResponse;
  } = object {
    let { events; broadcastQueue } = state;

    let InformModule = Inform.init(state, deployer);

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func publish(caller: Principal, eventName: Text, payload: Candy.CandyValue): PublishResponse {
      if (eventName.size() > Const.EVENT_NAME_LENGTH_LIMIT) Debug.trap(Errors.EVENT_NAME_LENGTH);

      let eventId = state.eventId + 1;

      Map.set(events, nhash, eventId, {
        id = eventId;
        eventName = eventName;
        publisherId = caller;
        payload = payload;
        createdAt = time();
        var nextBroadcastTime = time();
        var numberOfAttempts = 0:Nat8;
        eventRequests = Set.new(phash);
        subscribers = Map.new<Principal, Nat8>(phash);
      });

      Set.addAfter(broadcastQueue, nhash, eventId, state.eventId);

      state.eventId := eventId;

      return { eventInfo = unwrap(InformModule.getEventInfo(deployer, caller, eventId)) };
    };
  };
};
