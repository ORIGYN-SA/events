import Debug "mo:base/Debug";
import Errors "../../../common/errors";
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
};
