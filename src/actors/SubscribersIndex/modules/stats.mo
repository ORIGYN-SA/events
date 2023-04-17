import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Set "mo:map/Set";
import { n32hash; n64hash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type MergeStatsResponse = [(Principal, Text, Types.SharedStats)];

  public type MergeStatsParams = (statsBatch: [(Principal, Text, Types.SharedStats)]);

  public type MergeStatsFullParams = (caller: Principal, state: State.SubscribersIndexState, params: MergeStatsParams);

  public func mergeSubscriptionStats((caller, state, (statsBatch)): MergeStatsFullParams): async* MergeStatsResponse {
    if (not Set.has(state.broadcastIds, phash, caller)) Debug.trap(Errors.PERMISSION_DENIED);

    return [];
  };
};
