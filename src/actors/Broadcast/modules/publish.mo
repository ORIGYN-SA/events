import Candy "mo:candy/types";
import Const "../../../common/const";
import Debug "mo:base/Debug";
import Deliver "./deliver";
import Errors "../../../common/errors";
import Info "./info";
import Map "mo:map/Map";
import Set "mo:map/Set";
import { setTimer; time } "mo:prim";
import { unwrap } "../../../utils/misc";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type PublishResponse = {
    eventInfo: Types.SharedEvent;
    broadcastVersion: Nat64;
  };

  public type PublishParams = (eventName: Text, payload: Candy.CandyValue);

  public type PublishFullParams = (caller: Principal, state: State.BroadcastState, params: PublishParams);

  public func publish((caller, state, (eventName, payload)): PublishFullParams): async* PublishResponse {
    if (not state.active) Debug.trap(Errors.INACTIVE_CANISTER);

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
      var lastSubscriberId = null:?Principal;
      var lastSubscribersStoreId = null:?Principal;
      sendRequests = Set.new(phash);
      subscribers = Set.new(phash);
    });

    Set.addAfter(state.broadcastQueue, nhash, eventId, state.eventId);

    state.eventId := eventId;

    if (not state.broadcastQueued) {
      ignore Deliver.broadcast(state);

      state.broadcastQueued := true;
    };

    let eventInfo = unwrap(Info.getEventInfo(state.mainId, state, (caller, eventId)));

    return { eventInfo; broadcastVersion = state.broadcastVersion };
  };
};
