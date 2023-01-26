import Const "../../../common/const";
import Map "mo:map/Map";
import Principal "mo:base/Principal";
import PublishersIndex "../../PublishersIndex/interface";
import PublishersStore "../../PublishersStore/interface";
import Set "mo:map/Set";
import Stats "../../../common/stats";
import SubscribersStore "../../SubscribersStore/interface";
import { setTimer; time } "mo:prim";
import { nhash; thash; phash } "mo:map/Map";
import { nat8ToNat64 } "../../../utils/misc";
import { Types; State } "../../../migrations/types";

module {
  func broadcastEvent(state: State.BroadcastState, event: State.Event): async* () {
    let publishersIndex = actor(Principal.toText(state.publishersIndexId)):PublishersIndex.PublishersIndex;

    let publisherLocation = await publishersIndex.getPublisherLocation(event.publisherId);

    let publishersStore = actor(Principal.toText(publisherLocation)):PublishersStore.PublishersStore;

    let { publication } = await publishersStore.supplyPublicationData(event.publisherId, event.eventName);

    let subscriberIds = if (event.numberOfAttempts > 0) Set.toArray(event.subscribers) else [];

    let subscribersStoreIter = switch (event.lastSubscribersStoreId) {
      case (?lastSubscribersStoreId) Set.keysFrom(state.subscribersStoreIds, phash, lastSubscribersStoreId).movePrev();
      case (_) Set.keys(state.subscribersStoreIds);
    };

    for (subscribersStoreId in subscribersStoreIter) {
      let subscribersStore = actor(Principal.toText(subscribersStoreId)):SubscribersStore.SubscribersStore;

      event.lastSubscriberId := null;
      event.lastSubscribersStoreId := ?subscribersStoreId;

      label subscribersStoreLoop loop {
        let { subscribersBatch; finalBatch } = await subscribersStore.supplySubscribersBatch(event.eventName, event.payload, {
          from = event.lastSubscriberId;
          whitelist = publication.whitelist;
          subscriberIds = subscriberIds;
          randomSeed = state.randomSeed;
        });

        let subscribersIter = subscribersBatch.vals();
        var notificationsCount = 0;
        var iterActive = true;

        state.randomSeed +%= 1;

        while (iterActive) await async label broadcastBatch {
          for ((subscriberId, listenerId) in subscribersIter) {
            let listenerActor = actor(Principal.toText(listenerId)):Types.ListenerActor;

            Set.delete(event.sendRequests, phash, subscriberId);

            ignore listenerActor.handleEvent(event.id, event.publisherId, event.eventName, event.payload);

            Stats.update(state.publicationStats, event.publisherId, event.eventName, {
              Stats.empty with
              numberOfNotifications = 1:Nat64;
              numberOfResendNotifications = if (event.numberOfAttempts > 0) 1:Nat64 else 0:Nat64;
            });

            Stats.update(state.subscriptionStats, subscriberId, event.eventName, {
              Stats.empty with
              numberOfNotifications = 1:Nat64;
              numberOfResendNotifications = if (event.numberOfAttempts > 0) 1:Nat64 else 0:Nat64;
            });

            event.lastSubscriberId := ?subscriberId;

            Set.add(event.subscribers, phash, subscriberId);

            notificationsCount += 1;

            if (notificationsCount % Const.SYNC_CALLS_LIMIT == 0) break broadcastBatch;
          };

          iterActive := false;
        };

        if (finalBatch) break subscribersStoreLoop;
      };
    };

    event.lastSubscriberId := null;
    event.lastSubscribersStoreId := null;
    event.numberOfAttempts += 1;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func broadcast(state: State.BroadcastState): async* () {
    try {
      for (eventId in Set.keys(state.broadcastQueue)) ignore do ?{
        await* broadcastEvent(state, Map.get(state.events, nhash, eventId)!);
      };

      state.broadcastTimerId := 0;
    } catch (err) {
      state.broadcastTimerId := 0;
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func resendCheck(state: State.BroadcastState) {
    for (event in Map.vals(state.events)) {
      if (Set.size(event.subscribers) > 0 and event.nextBroadcastTime <= time()) {
        if (event.numberOfAttempts < Const.RESEND_ATTEMPTS_LIMIT) {
          Set.add(state.broadcastQueue, nhash, event.id);
        } else {
          Set.clear(event.subscribers);
        };
      };
    };

    if (state.broadcastTimerId == 0 and Set.size(state.broadcastQueue) > 0) {
      state.broadcastTimerId := setTimer(0, false, func(): async () { await* broadcast(state) });
    };
  };
};
