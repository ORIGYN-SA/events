import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Stats "../../../common/stats";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type TransferStats = (Principal, Text, Types.SharedStats);

  public type ConsumedStats = (Principal, Text);

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.SubscribersStoreState, deployer: Principal): {
    consumeSubscriptionStats: (caller: Principal, TransferStats: [TransferStats]) -> [(Principal, Text)];
  } = object {
    let { canisters; subscriptions } = state;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func consumeSubscriptionStats(caller: Principal, TransferStats: [TransferStats]): [ConsumedStats] {
      if (not Map.has(canisters, phash, caller)) Debug.trap(Errors.PERMISSION_DENIED);

      let consumedStats = Buffer.Buffer<ConsumedStats>(0);

      for ((subscriberId, eventName, stats) in TransferStats.vals()) ignore do ?{
        let subscriptionGroup = Map.get(subscriptions, thash, eventName)!;
        let subscription = Map.get(subscriptionGroup, phash, subscriberId)!;

        Stats.merge(subscription.stats, stats);

        consumedStats.add(subscriberId, eventName);
      };

      return Buffer.toArray(consumedStats);
    };
  };
};
