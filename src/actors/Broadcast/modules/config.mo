import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Option "mo:base/Option";
import Prim "mo:prim";
import Set "mo:map/Set";
import { time } "mo:prim";
import { n32hash; n64hash; thash; phash } "mo:map/Map";
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

  public type QueueOwerflowsResponse = [Types.TimeRange];

  public type QueueOwerflowsParams = (from: Nat64, to: Nat64);

  public type QueueOwerflowsFullParams = (caller: Principal, state: State.BroadcastState, params: QueueOwerflowsParams);

  public func getQueueOwerflows((caller, state, (from, to)): QueueOwerflowsFullParams): QueueOwerflowsResponse {
    if (caller != state.mainId) Debug.trap(Errors.PERMISSION_DENIED);

    return Map.toArrayMap<Nat64, Nat64, Types.TimeRange>(state.queueOverflows, func(startTime, endTime) {
      let targetTime = if (endTime == 0) time() else endTime;

      return if (endTime >= from and startTime <= to) ?(startTime, targetTime) else null;
    });
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type Status = {
    active: Bool;
    broadcastVersion: Nat64;
  };

  public type StatusResponse = ();

  public type StatusParams = (status: Status);

  public type StatusFullParams = (caller: Principal, state: State.BroadcastState, params: StatusParams);

  public func setStatus((caller, state, (status)): StatusFullParams): StatusResponse {
    if (caller != state.mainId) Debug.trap(Errors.PERMISSION_DENIED);

    state.active := status.active;
    state.broadcastVersion := status.broadcastVersion;
  };
};
