import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Stats "../../../common/stats";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type CosumeStatsResponse = ();

  public type CosumeStatsParams = (statsBatch: [(Principal, Text, Types.SharedStats)]);

  public type CosumeStatsFullParams = (caller: Principal, state: State.PublishersStoreState, params: CosumeStatsParams);

  public func consumePublicationStats((caller, state, (statsBatch)): CosumeStatsFullParams): CosumeStatsResponse {
    if (caller != state.publishersIndexId) Debug.trap(Errors.PERMISSION_DENIED);

    for ((publisherId, eventName, stats) in statsBatch.vals()) ignore do ?{
      let publicationGroup = Map.get(state.publications, thash, eventName)!;
      let publication = Map.get(publicationGroup, phash, publisherId)!;

      Stats.merge(publication.stats, stats);
    };
  };
};
