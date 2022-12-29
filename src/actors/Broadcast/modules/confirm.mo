import Map "mo:map/Map";
import Set "mo:map/Set";
import Stats "../../../common/stats";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type ConfirmEventResponse = {
    confirmed: Bool;
  };

  public type ConfirmEventParams = (eventId: Nat);

  public type ConfirmEventFullParams = (caller: Principal, state: State.BroadcastState, params: ConfirmEventParams);

  public func confirmEventProcessed((caller, state, (eventId)): ConfirmEventFullParams): ConfirmEventResponse {
    var confirmed = false;

    ignore do ?{
      let event = Map.get(state.events, nhash, eventId)!;

      ignore Map.remove(event.subscribers, phash, caller)!;

      Set.delete(event.eventRequests, phash, caller);

      confirmed := true;

      Stats.update(state.publicationStats, caller, event.eventName, { Stats.empty with numberOfConfirmations = 1:Nat64 });

      Stats.update(state.subscriptionStats, caller, event.eventName, { Stats.empty with numberOfConfirmations = 1:Nat64 });
    };

    return { confirmed };
  };
};
