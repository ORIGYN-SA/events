import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Stats "../../../common/stats";
import { n32hash; n64hash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type StatsBatchItem = (publisherId: Principal, eventName: Text, stats: Types.SharedStats);

  public type MergeStatsResponse = ();

  public type MergeStatsParams = (statsBatch: [StatsBatchItem]);

  public type MergeStatsFullParams = (caller: Principal, state: State.SubscribersStoreState, params: MergeStatsParams);

  public func mergeSubscriptionStats((caller, state, (statsBatch)): MergeStatsFullParams): MergeStatsResponse {
    if (caller != state.subscribersIndexId) Debug.trap(Errors.PERMISSION_DENIED);

    for ((subscriberId, eventName, stats) in statsBatch.vals()) label iteration {
      let ?subscriptionGroup = Map.get(state.subscriptions, thash, eventName) else break iteration;
      let ?subscription = Map.get(subscriptionGroup, phash, subscriberId) else break iteration;

      Stats.merge(subscription.stats, stats);
    };
  };
};
