import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Set "mo:map/Set";
import Stats "../../../common/stats";
import { n32hash; n64hash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type ConfirmEventResponse = {
    confirmed: Bool;
  };

  public type ConfirmEventParams = (eventId: Nat64);

  public type ConfirmEventFullParams = (caller: Principal, state: State.BroadcastState, params: ConfirmEventParams);

  public func confirmEventReceipt((caller, state, (eventId)): ConfirmEventFullParams): ConfirmEventResponse {
    let ?event = Map.get(state.events, n64hash, eventId) else Debug.trap(Errors.EVENT_NOT_FOUND);

    if (not Set.has(event.subscribers, phash, caller)) return { confirmed = false };

    Set.delete(event.subscribers, phash, caller);
    Set.delete(event.sendRequests, phash, caller);

    Stats.update(state.publicationStats, caller, event.eventName, { Stats.empty with numberOfConfirmations = 1:Nat64 });
    Stats.update(state.subscriptionStats, caller, event.eventName, { Stats.empty with numberOfConfirmations = 1:Nat64 });

    return { confirmed = true };
  };
};
