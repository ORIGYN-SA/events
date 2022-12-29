import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Stats "../../../common/stats";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type ConsumeStatsResponse = ();

  public type ConsumeStatsParams = (statsBatch: [(Principal, Text, Types.SharedStats)]);

  public type ConsumeStatsFullParams = (caller: Principal, state: State.SubscribersStoreState, params: ConsumeStatsParams);

  public func consumeSubscriptionStats((caller, state, (statsBatch)): ConsumeStatsFullParams): ConsumeStatsResponse {
    if (caller != state.subscribersIndexId) Debug.trap(Errors.PERMISSION_DENIED);

    for ((subscriberId, eventName, stats) in statsBatch.vals()) ignore do ?{
      let subscriptionGroup = Map.get(state.subscriptions, thash, eventName)!;
      let subscription = Map.get(subscriptionGroup, phash, subscriberId)!;

      Stats.merge(subscription.stats, stats);
    };
  };
};
