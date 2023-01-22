import Debug "mo:base/Debug";
import Errors "../../../common/errors";
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
};
