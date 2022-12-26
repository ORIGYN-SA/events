import Candy "mo:candy/types";
import Const "../../../common/const";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Info "./info";
import Map "mo:map/Map";
import Set "mo:map/Set";
import { time } "mo:prim";
import { unwrap } "../../../utils/misc";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type PublishResponse = {
    eventInfo: Types.SharedEvent;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.BroadcastState, deployer: Principal): {
    publish: (caller: Principal, eventName: Text, payload: Candy.CandyValue) -> PublishResponse;
  } = object {
    let { events; broadcastQueue } = state;

    let InfoModule = Info.init(state, deployer);

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

      return { eventInfo = unwrap(InfoModule.getEventInfo(deployer, caller, eventId)) };
    };
  };
};
