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

  public type PublishParams = (eventName: Text, payload: Candy.CandyValue);

  public type PublishFullParams = (caller: Principal, state: State.BroadcastState, params: PublishParams);

  public func publish((caller, state, (eventName, payload)): PublishFullParams): PublishResponse {
    if (eventName.size() > Const.EVENT_NAME_LENGTH_LIMIT) Debug.trap(Errors.EVENT_NAME_LENGTH);

    let eventId = state.eventId + 1;

    Map.set(state.events, nhash, eventId, {
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

    Set.addAfter(state.broadcastQueue, nhash, eventId, state.eventId);

    state.eventId := eventId;

    return { eventInfo = unwrap(Info.getEventInfo(state.mainId, state, (caller, eventId))) };
  };
};
