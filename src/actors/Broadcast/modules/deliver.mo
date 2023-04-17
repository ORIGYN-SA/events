import Const "../../../common/const";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Info "./info";
import Map "mo:map/Map";
import Principal "mo:base/Principal";
import PublishersIndex "../../PublishersIndex/main";
import PublishersStore "../../PublishersStore/main";
import Queue "./queue";
import Set "mo:map/Set";
import Stats "../../../common/stats";
import SubscribersStore "../../SubscribersStore/main";
import { setTimer; time } "mo:prim";
import { n32hash; n64hash; thash; phash } "mo:map/Map";
import { nat8ToNat64 } "../../../utils/misc";
import { Types; State } "../../../migrations/types";

module {
  func broadcastEvent(state: State.BroadcastState, event: State.Event): async* () {
    let publishersIndex = actor(Principal.toText(state.publishersIndexId)):PublishersIndex.PublishersIndex;

    let publisherLocation = await publishersIndex.getPublisherLocation(event.publisherId);

    let publishersStore = actor(Principal.toText(publisherLocation)):PublishersStore.PublishersStore;

    let { publication } = await publishersStore.supplyPublicationData(event.publisherId, event.eventName);

    let ?eventInfo = Info.getEventInfo(state.mainId, state, (event.publisherId, event.id));

    let subscriberIds = if (event.numberOfAttempts > 0) Set.toArray(event.subscribers) else [];

    let subscribersStoreIter = switch (event.lastSubscribersStoreId) {
      case (null) Set.keys(state.subscribersStoreIds);
      case (_) Set.keysFrom(state.subscribersStoreIds, phash, event.lastSubscribersStoreId).movePrev();
    };

    for (subscribersStoreId in subscribersStoreIter) {
      let subscribersStore = actor(Principal.toText(subscribersStoreId)):SubscribersStore.SubscribersStore;

      event.lastSubscriberId := null;
      event.lastSubscribersStoreId := ?subscribersStoreId;

      label subscribersStoreLoop loop {
        let { subscribersBatch; finalBatch } = await subscribersStore.supplySubscribersBatch(event.eventName, event.payload, {
          from = event.lastSubscriberId;
          eventType = event.eventType;
          publisherId = event.publisherId;
          subscriberWhitelist = publication.subscriberWhitelist;
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

            ignore listenerActor.handleEvent(eventInfo);

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

    Queue.remove(state, event);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func broadcast(state: State.BroadcastState): async () {
    try await async {
      label broadcastLoop loop {
        let ?event = Queue.next(state) else break broadcastLoop;

        await* broadcastEvent(state, event);
      };

      state.broadcastQueued := false;
    } catch (err) {
      Debug.print(Error.message(err));

      ignore setTimer(Const.BROADCAST_RETRY_DELAY, false, func(): async () { await broadcast(state) });

      state.broadcastQueued := true;
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func resendCheck(state: State.BroadcastState): async* () {
    for (event in Map.vals(state.events)) {
      if (not Set.empty(event.subscribers) and event.nextBroadcastTime <= time()) {
        if (event.numberOfAttempts < Const.RESEND_ATTEMPTS_LIMIT) {
          Queue.add(state, event, #Secondary);
        } else {
          Set.clear(event.subscribers);
        };
      };
    };

    if (not state.broadcastQueued and not Queue.empty(state)) {
      ignore broadcast(state);

      state.broadcastQueued := true;
    };
  };
};
