import Buffer "mo:base/Buffer";
import Candy "mo:candy/types";
import CandyUtils "mo:candy_utils/CandyUtils";
import Const "../../../common/const";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Set "mo:map/Set";
import { nat32ToNat } "mo:prim";
import { hashInt; hashPrincipal } "mo:map/utils";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type SubscribersBatchOptions = {
    from: ?Principal;
    whitelist: [Principal];
    subscriberIds: [Principal];
    randomSeed: Nat32;
  };

  public type SubscribersBatchItem = (subscriberId: Principal, listenerId: Principal);

  public type SubscribersBatchResponse = {
    subscribersBatch: [SubscribersBatchItem];
    finalBatch: Bool;
  };

  public type SubscribersBatchParams = (eventName: Text, payload: Candy.CandyValue, options: SubscribersBatchOptions);

  public type SubscribersBatchFullParams = (caller: Principal, state: State.SubscribersStoreState, params: SubscribersBatchParams);

  public func supplySubscribersBatch((caller, state, (eventName, payload, options)): SubscribersBatchFullParams): SubscribersBatchResponse {
    if (not Set.has(state.broadcastIds, phash, caller)) Debug.trap(Errors.PERMISSION_DENIED);

    let subscribersBatch = Buffer.Buffer<SubscribersBatchItem>(0);
    var finalBatch = false;

    ignore do ?{
      let subscriptionGroup = Map.get(state.subscriptions, thash, eventName)!;

      let subscriberIdsIter = if (options.subscriberIds.size() > 0) {
        options.subscriberIds.vals();
      } else if (options.whitelist.size() > 0) {
        options.whitelist.vals();
      } else if (options.from != null) {
        Map.keysFrom(subscriptionGroup, phash, options.from!);
      } else {
        Map.keys(subscriptionGroup);
      };

      var rateSeed = hashInt(nat32ToNat(hashPrincipal(caller) +% options.randomSeed +% 1));
      var listenersSeed = hashInt(nat32ToNat(hashPrincipal(caller) +% options.randomSeed +% 2));

      for (subscriberId in subscriberIdsIter) ignore do ?{
        let subscriber = Map.get(state.subscribers, phash, subscriberId)!;
        let subscription = Map.get(subscriptionGroup, phash, subscriberId)!;

        rateSeed +%= 1;
        listenersSeed +%= 1;

        if (subscription.active and not subscription.stopped and hashInt(nat32ToNat(rateSeed)) % 100 <= subscription.rate) {
          if (subscription.filterPath == null or CandyUtils.get(payload, subscription.filterPath!) != #Bool(false)) {
            let listenersSize = subscriber.confirmedListeners.size();

            subscribersBatch.add(subscriberId, subscriber.confirmedListeners[nat32ToNat(hashInt(nat32ToNat(listenersSeed))) % listenersSize]);

            if (subscribersBatch.size() >= Const.SUBSCRIBERS_BATCH_SIZE) return {
              subscribersBatch = Buffer.toArray(subscribersBatch);
              finalBatch = subscriberIdsIter.next() == null;
            };
          };
        };
      };
    };

    return { 
      subscribersBatch = Buffer.toArray(subscribersBatch);
      finalBatch = true;
    };
  };
};
