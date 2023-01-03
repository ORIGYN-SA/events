import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Set "mo:map/Set";
import { take } "../../../utils/misc";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type TransferStatsResponse = [(Principal, Text, Types.SharedStats)];

  public type TransferStatsParams = (statsBatch: [(Principal, Text, Types.SharedStats)]);

  public type TransferStatsFullParams = (caller: Principal, state: State.SubscribersIndexState, params: TransferStatsParams);

  public func transferSubscriptionStats((caller, state, (statsBatch)): TransferStatsFullParams): async* TransferStatsResponse {
    if (not Set.has(state.broadcastIds, phash, caller)) Debug.trap(Errors.PERMISSION_DENIED);

    return [];
  };
};
