import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Prim "mo:prim";
import Set "mo:map/Set";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type SubscribersStoreIdsResponse = ();

  public type SubscribersStoreIdsParams = (subscribersStoreIds: [Principal]);

  public type SubscribersStoreIdsFullParams = (caller: Principal, state: State.BroadcastState, params: SubscribersStoreIdsParams);

  public func addSubscribersStoreIds((caller, state, (subscribersStoreIds)): SubscribersStoreIdsFullParams): SubscribersStoreIdsResponse {
    if (caller != state.mainId) Debug.trap(Errors.PERMISSION_DENIED);

    for (subscribersStoreId in subscribersStoreIds.vals()) Set.add(state.subscribersStoreIds, phash, subscribersStoreId);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type CanisterMetricsResponse = Types.CanisterMetrics;

  public type CanisterMetricsParams = ();

  public type CanisterMetricsFullParams = (caller: Principal, state: State.BroadcastState, params: CanisterMetricsParams);

  public func getCanisterMetrics((caller, state, ()): CanisterMetricsFullParams): CanisterMetricsResponse {
    if (caller != state.mainId) Debug.trap(Errors.PERMISSION_DENIED);

    return {
      heapSize = Prim.rts_heap_size();
      balance = Cycles.balance();
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type ActiveStatusResponse = ();

  public type ActiveStatusParams = (active: Bool, broadcastVersion: Nat64);

  public type ActiveStatusFullParams = (caller: Principal, state: State.BroadcastState, params: ActiveStatusParams);

  public func setActiveStatus((caller, state, (active, broadcastVersion)): ActiveStatusFullParams): ActiveStatusResponse {
    if (caller != state.mainId) Debug.trap(Errors.PERMISSION_DENIED);

    state.active := active;
    state.broadcastVersion := broadcastVersion;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type BroadcastVersionResponse = ();

  public type BroadcastVersionParams = (broadcastVersion: Nat64);

  public type BroadcastVersionFullParams = (caller: Principal, state: State.BroadcastState, params: BroadcastVersionParams);

  public func setBroadcastVersion((caller, state, (broadcastVersion)): BroadcastVersionFullParams): BroadcastVersionResponse {
    if (caller != state.mainId) Debug.trap(Errors.PERMISSION_DENIED);

    state.broadcastVersion := broadcastVersion;
  };
};
