import Map "mo:map/Map";
import Set "mo:map/Set";
import Stats "../../../common/stats";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type ConfirmEventResponse = {
    confirmed: Bool;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.BroadcastState, deployer: Principal): {
    confirmEventProcessed: (caller: Principal, eventId: Nat) -> ConfirmEventResponse;
  } = object {
    let { events; publicationStats; subscriptionStats } = state;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func confirmEventProcessed(caller: Principal, eventId: Nat): ConfirmEventResponse {
      var confirmed = false;

      ignore do ?{
        let event = Map.get(events, nhash, eventId)!;

        ignore Map.remove(event.subscribers, phash, caller)!;

        Set.delete(event.eventRequests, phash, caller);

        confirmed := true;

        Stats.update(publicationStats, caller, event.eventName, { Stats.empty with numberOfConfirmations = 1:Nat64 });

        Stats.update(subscriptionStats, caller, event.eventName, { Stats.empty with numberOfConfirmations = 1:Nat64 });
      };

      return { confirmed };
    };
  };
};
