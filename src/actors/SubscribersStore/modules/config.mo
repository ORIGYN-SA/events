import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Prim "mo:prim";
import Set "mo:map/Set";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type BroadcastIdsResponse = ();

  public type BroadcastIdsParams = (broadcastIds: [Principal]);

  public type BroadcastIdsFullParams = (caller: Principal, state: State.SubscribersStoreState, params: BroadcastIdsParams);

  public func addBroadcastIds((caller, state, (broadcastIds)): BroadcastIdsFullParams): BroadcastIdsResponse {
    if (caller != state.mainId) Debug.trap(Errors.PERMISSION_DENIED);

    for (broadcastId in broadcastIds.vals()) Set.add(state.broadcastIds, phash, broadcastId);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type CanisterMetricsResponse = Types.CanisterMetrics;

  public type CanisterMetricsParams = ();

  public type CanisterMetricsFullParams = (caller: Principal, state: State.SubscribersStoreState, params: CanisterMetricsParams);

  public func getCanisterMetrics((caller, state, ()): CanisterMetricsFullParams): CanisterMetricsResponse {
    if (caller != state.mainId) Debug.trap(Errors.PERMISSION_DENIED);

    return {
      heapSize = Prim.rts_heap_size();
      balance = Cycles.balance();
    };
  };
};
