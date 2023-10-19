import Buffer "mo:base/Buffer";
import Candy "mo:candy2/types";
import Const "../../../common/const";
import Debug "mo:base/Debug";
import Deliver "./deliver";
import Errors "../../../common/errors";
import Info "./info";
import Map "mo:map/Map";
import Queue "./queue";
import Set "mo:map/Set";
import { setTimer; time } "mo:prim";
import { n32hash; n64hash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type PublishResponse = {
    eventInfo: Types.SharedEvent;
    broadcastVersion: Nat64;
  };

  public type PublishParams = (eventName: Text, payload: Candy.CandyShared);

  public type PublishFullParams = (caller: Principal, state: State.BroadcastState, params: PublishParams);

  public func publish((caller, state, (eventName, payload)): PublishFullParams): async* PublishResponse {
    if (not state.active) Debug.trap(Errors.INACTIVE_CANISTER);

    if (eventName.size() > Const.EVENT_NAME_LENGTH_LIMIT) Debug.trap(Errors.EVENT_NAME_LENGTH);

    let event = {
      id = state.eventId;
      eventName = eventName;
      publisherId = caller;
      eventType = #Public;
      payload = payload;
      createdAt = time();
      var nextBroadcastTime = time();
      var numberOfAttempts = 0:Nat8;
      var lastSubscriberId = null:?Principal;
      var lastSubscribersStoreId = null:?Principal;
      sendRequests = Set.new(phash);
      subscribers = Set.new(phash);
    };

    Map.set(state.events, n64hash, state.eventId, event);

    Queue.add(state, event, #Primary);

    if (not state.broadcastQueued) {
      ignore Deliver.broadcast(state);

      state.broadcastQueued := true;
    };

    let ?eventInfo = Info.getEventInfo(state.mainId, state, (caller, state.eventId));

    state.eventId += 1;

    return { eventInfo; broadcastVersion = state.broadcastVersion };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type PublishBatchResponse = {
    eventsInfo: [Types.SharedEvent];
    broadcastVersion: Nat64;
  };

  public type PublishBatchParams = (events: [Types.EventEntry]);

  public type PublishBatchFullParams = (caller: Principal, state: State.BroadcastState, params: PublishBatchParams);

  public func publishBatch((caller, state, (events)): PublishBatchFullParams): async* PublishBatchResponse {
    if (not state.active) Debug.trap(Errors.INACTIVE_CANISTER);

    let eventsInfo = Buffer.Buffer<Types.SharedEvent>(events.size());

    for ((eventName, payload) in events.vals()) {
      let { eventInfo } = await* publish(caller, state, (eventName, payload));

      eventsInfo.add(eventInfo);
    };

    return { eventsInfo = Buffer.toArray(eventsInfo); broadcastVersion = state.broadcastVersion };
  };
};
