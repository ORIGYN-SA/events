import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Stats "../../../common/stats";
import { n32hash; n64hash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type MergeStatsResponse = ();

  public type MergeStatsParams = (statsBatch: [Types.StatsEntry]);

  public type MergeStatsFullParams = (caller: Principal, state: State.PublishersStoreState, params: MergeStatsParams);

  public func mergePublicationStats((caller, state, (statsBatch)): MergeStatsFullParams): MergeStatsResponse {
    if (caller != state.publishersIndexId) Debug.trap(Errors.PERMISSION_DENIED);

    for ((publisherId, eventName, stats) in statsBatch.vals()) label iteration {
      let ?publicationGroup = Map.get(state.publications, thash, eventName) else break iteration;
      let ?publication = Map.get(publicationGroup, phash, publisherId) else break iteration;

      Stats.merge(publication.stats, stats);
    };
  };
};
