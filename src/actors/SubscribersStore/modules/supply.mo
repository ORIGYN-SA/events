import Buffer "mo:base/Buffer";
import Candy "mo:candy2/types";
import CandyUtils "mo:candy_utils/CandyUtils";
import Const "../../../common/const";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Set "mo:map/Set";
import { nat32ToNat } "mo:prim";
import { hashNat32; hashPrincipal } "mo:map/Map";
import { n32hash; n64hash; thash; phash } "mo:map/Map";
import { unwrap } "../../../utils/misc";
import { Types; State } "../../../migrations/types";

module {
  public type SubscribersBatchOptions = {
    from: ?Principal;
    eventType: State.EventType;
    publisherId: Principal;
    subscriberWhitelist: [Principal];
    subscriberIds: [Principal];
    randomSeed: Nat32;
  };

  public type SubscribersBatchItem = (subscriberId: Principal, listenerId: Principal);

  public type SubscribersBatchResponse = {
    subscribersBatch: [SubscribersBatchItem];
    finalBatch: Bool;
  };

  public type SubscribersBatchParams = (eventName: Text, payload: Candy.CandyShared, options: SubscribersBatchOptions);

  public type SubscribersBatchFullParams = (caller: Principal, state: State.SubscribersStoreState, params: SubscribersBatchParams);

  public func supplySubscribersBatch((caller, state, (eventName, payload, options)): SubscribersBatchFullParams): SubscribersBatchResponse {
    if (not Set.has(state.broadcastIds, phash, caller)) Debug.trap(Errors.PERMISSION_DENIED);

    let ?subscriptionGroup = Map.get(state.subscriptions, thash, eventName) else return { subscribersBatch = []; finalBatch = true };

    let subscriberIdsIter = if (options.subscriberIds.size() > 0) {
      options.subscriberIds.vals();
    } else if (options.subscriberWhitelist.size() > 0) {
      options.subscriberWhitelist.vals();
    } else {
      Map.keysFrom(subscriptionGroup, phash, options.from);
    };

    let subscribersBatch = Buffer.Buffer<SubscribersBatchItem>(0);
    var payloadUnshared = null:?Candy.Candy;
    var rateSeed = hashNat32(hashPrincipal(caller) +% options.randomSeed +% 1);
    var listenersSeed = hashNat32(hashPrincipal(caller) +% options.randomSeed +% 2);

    for (subscriberId in subscriberIdsIter) label iteration {
      let ?subscriber = Map.get(state.subscribers, phash, subscriberId) else break iteration;
      let ?subscription = Map.get(subscriptionGroup, phash, subscriberId) else break iteration;
      let listenersSize = subscriber.confirmedListeners.size();

      rateSeed +%= 1;
      listenersSeed +%= 1;

      if (not subscription.active or subscription.stopped or hashNat32(rateSeed) % 100 > subscription.rate) break iteration;

      if (options.eventType != #System and Set.contains(subscription.publisherWhitelist, phash, options.publisherId) == ?false) break iteration;

      if (subscription.filterPath != null) {
        payloadUnshared := switch (payloadUnshared) { case (null) ?Candy.unshare(payload); case (_) payloadUnshared };

        switch (CandyUtils.get(unwrap(payloadUnshared), subscription.filterPath)) { case (#Bool(false)) break iteration; case (_) {} };
      };

      subscribersBatch.add(subscriberId, subscriber.confirmedListeners[nat32ToNat(hashNat32(listenersSeed)) % listenersSize]);

      if (subscribersBatch.size() >= Const.SUBSCRIBERS_BATCH_SIZE) return {
        subscribersBatch = Buffer.toArray(subscribersBatch);
        finalBatch = subscriberIdsIter.next() == null;
      };
    };

    return { subscribersBatch = Buffer.toArray(subscribersBatch); finalBatch = true };
  };
};
