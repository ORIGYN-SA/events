import Buffer "mo:base/Buffer";
import Candy "mo:candy/types";
import CandyUtils "mo:candy_utils/CandyUtils";
import Const "../../../common/const";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Set "mo:map/Set";
import { nat8ToNat } "mo:prim";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type SubscribersBatchOptions = {
    from: ?Principal;
    rateSeed: Nat;
    listenersSeed: Nat;
  };

  public type SubscribersBatchResponse = [(Principal, Principal)];

  public type SubscribersBatchParams = (eventName: Text, payload: Candy.CandyValue, options: SubscribersBatchOptions);

  public type SubscribersBatchFullParams = (caller: Principal, state: State.SubscribersStoreState, params: SubscribersBatchParams);

  public func supplySubscribersBatch((caller, state, (eventName, payload, options)): SubscribersBatchFullParams): SubscribersBatchResponse {
    if (not Set.has(state.broadcastIds, phash, caller)) Debug.trap(Errors.PERMISSION_DENIED);

    let result = Buffer.Buffer<(Principal, Principal)>(0);

    ignore do ?{
      let subscriptionGroup = Map.get(state.subscriptions, thash, eventName)!;

      let subscriberIdsIter = if (options.from != null) Map.keysFrom(subscriptionGroup, phash, options.from!) else Map.keys(subscriptionGroup);

      label subscribersBatch for (subscriberId in subscriberIdsIter) ignore do ?{
        let subscriber = Map.get(state.subscribers, phash, subscriberId)!;
        let subscription = Map.get(subscriptionGroup, phash, subscriberId)!;

        if (options.rateSeed % 100 <= nat8ToNat(subscription.rate)) {
          if (subscription.filterPath == null or CandyUtils.get(payload, subscription.filterPath!) != #Bool(false)) {
            let listenersSize = subscriber.confirmedListeners.size();

            result.add(subscriberId, subscriber.confirmedListeners[options.listenersSeed % listenersSize]);

            if (result.size() >= Const.SUBSCRIBERS_BATCH_SIZE) break subscribersBatch;
          };
        };
      };
    };

    return Buffer.toArray(result);
  };
};
