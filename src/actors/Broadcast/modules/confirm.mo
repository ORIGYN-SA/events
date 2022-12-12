import Const "../../../common/const";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Inform "./inform";
import Map "mo:map/Map";
import MigrationTypes "../../../migrations/types";
import Option "mo:base/Option";
import Prim "mo:prim";
import Set "mo:map/Set";
import Stats "../../../common/stats";
import Types "../../../common/types";
import Utils "../../../utils/misc";

module {
  let State = MigrationTypes.Current;

  let { get = coalesce } = Option;

  let { pthash } = Utils;

  let { nhash; thash; phash; lhash } = Map;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type ConfirmEventResponse = {
    confirmed: Bool;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.BroadcastState, deployer: Principal): {
    confirmEventProcessed: (caller: Principal, eventId: Nat) -> ConfirmEventResponse;
  } = object {
    let { events; publicationStatsBatch; subscriptionStatsBatch } = state;

    let InformModule = Inform.init(state, deployer);

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func confirmEventProcessed(caller: Principal, eventId: Nat): ConfirmEventResponse {
      var confirmed = false;

      ignore do ?{
        let event = Map.get(events, nhash, eventId)!;

        ignore Map.remove(event.subscribers, phash, caller)!;

        Set.delete(event.eventRequests, phash, caller);

        confirmed := true;

        let publicationStats = Map.update<(Principal, Text), State.Stats>(publicationStatsBatch, pthash, (caller, event.eventName), func(key, value) {
          return coalesce(value, Stats.defaultStats());
        });

        let subscriptionStats = Map.update<(Principal, Text), State.Stats>(subscriptionStatsBatch, pthash, (caller, event.eventName), func(key, value) {
          return coalesce(value, Stats.defaultStats());
        });

        publicationStats.numberOfConfirmations +%= 1;
        subscriptionStats.numberOfConfirmations +%= 1;
      };

      return { confirmed };
    };
  };
};
