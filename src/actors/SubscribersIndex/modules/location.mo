import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Set "mo:map/Set";
import { n32hash; n64hash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type GetLocationResponse = Principal;

  public type GetLocationParams = (subscriberId: Principal);

  public type GetLocationFullParams = (caller: Principal, state: State.SubscribersIndexState, params: GetLocationParams);

  public func getSubscriberLocation((caller, state, (subscriberId)): GetLocationFullParams): GetLocationResponse {
    if (not Set.has(state.broadcastIds, phash, caller)) Debug.trap(Errors.PERMISSION_DENIED);

    let ?subscriberStoreId = Map.get(state.subscribersLocation, phash, caller) else Debug.trap(Errors.SUBSCRIBER_NOT_FOUND);

    return subscriberStoreId;
  };
};
