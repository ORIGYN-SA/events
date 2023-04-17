import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Set "mo:map/Set";
import { n32hash; n64hash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type GetLocationResponse = Principal;

  public type GetLocationParams = (publisherId: Principal);

  public type GetLocationFullParams = (caller: Principal, state: State.PublishersIndexState, params: GetLocationParams);

  public func getPublisherLocation((caller, state, (publisherId)): GetLocationFullParams): GetLocationResponse {
    if (not Set.has(state.broadcastIds, phash, caller)) Debug.trap(Errors.PERMISSION_DENIED);

    let ?publishersStoreId = Map.get(state.publishersLocation, phash, publisherId) else Debug.trap(Errors.PUBLISHER_NOT_FOUND);

    return publishersStoreId;
  };
};
