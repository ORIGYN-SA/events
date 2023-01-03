import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Set "mo:map/Set";
import { take } "../../../utils/misc";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type GetLocationResponse = Principal;

  public type GetLocationParams = (publisherId: Principal);

  public type GetLocationFullParams = (caller: Principal, state: State.PublishersIndexState, params: GetLocationParams);

  public func getPublisherLocation((caller, state, (publisherId)): GetLocationFullParams): GetLocationResponse {
    if (not Set.has(state.broadcastIds, phash, caller)) Debug.trap(Errors.PERMISSION_DENIED);

    return take(Map.get(state.publishersLocation, phash, publisherId), Errors.PUBLISHER_NOT_FOUND);
  };
};
