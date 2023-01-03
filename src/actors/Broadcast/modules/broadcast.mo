import Const "../../../common/const";
import Map "mo:map/Map";
import Principal "mo:base/Principal";
import PublishersIndex "../../PublishersIndex/main";
import PublishersStore "../../PublishersStore/main";
import Set "mo:map/Set";
import { time } "mo:prim";
import { nhash; thash; phash } "mo:map/Map";
import { nat8ToNat64 } "../../../utils/misc";
import { Types; State } "../../../migrations/types";

module {
  func broadcastEvent(state: State.BroadcastState, event: State.Event): async* () {
    let bublishersIndex = actor(Principal.toText(state.publishersIndexId)):PublishersIndex.PublishersIndex;

    let publisherLocation = await bublishersIndex.getPublisherLocation(event.publisherId);

    let publishersStore = actor(Principal.toText(publisherLocation)):PublishersStore.PublishersStore;

    let { publisher; publication } = await publishersStore.supplyPublicationData(event.publisherId, event.eventName);

    if (event.numberOfAttempts < Const.RESEND_ATTEMPTS_LIMIT) {
      let subscribersIter = Map.entries(event.subscribers);
      let eventBroadcastStartTime = time();
      var notificationsCount = 0:Nat8;
      var iterActive = true;

      while (iterActive) await async label broadcastBatch {
        for ((subscriberId, numberOfAttempts) in subscribersIter) if (numberOfAttempts <= event.numberOfAttempts) {
          ignore do ?{
            let subscriptionGroup = Map.get(subscriptions, thash, event.eventName)!;
            let subscription = Map.get(subscriptionGroup, phash, subscriberId)!;

            if (subscription.active and not subscription.stopped) {
              let subscriber = Map.get(subscribers, phash, subscriberId)!;
              let listenerId = Set.popFront(subscriber.confirmedListeners)!;
              let listenerActor = actor(Principal.toText(listenerId)):Types.ListenerActor;

              Set.add(subscriber.confirmedListeners, phash, listenerId);
              Set.delete(event.eventRequests, phash, subscriberId);

              listenerActor.handleEvent(event.id, event.publisherId, event.eventName, event.payload);

              subscription.numberOfNotifications += 1;

              if (numberOfAttempts > 0) subscription.numberOfResendNotifications += 1;

              let publicationGroup = Map.get(publications, thash, event.eventName)!;
              let publication = Map.get(publicationGroup, phash, event.publisherId)!;

              publication.numberOfNotifications += 1;

              if (numberOfAttempts > 0) publication.numberOfResendNotifications += 1;
            };
          };

          Map.set(event.subscribers, phash, subscriberId, numberOfAttempts + 1);

          notificationsCount += 1;

          if (notificationsCount % Const.BROADCAST_BATCH_SIZE == 0) break broadcastBatch;
        };

        iterActive := false;
      };

      event.numberOfAttempts += 1;
      event.nextBroadcastTime := eventBroadcastStartTime + Const.RESEND_DELAY * 2 ** nat8ToNat64(event.numberOfAttempts - 1);
    } else {
      Map.delete(events, nhash, event.id);

      for (subscriberId in Map.keys(event.subscribers)) ignore do ?{
        let subscriptionGroup = Map.get(subscriptions, thash, event.eventName)!;
        let subscription = Map.get(subscriptionGroup, phash, subscriberId)!;

        Set.delete(subscription.events, nhash, event.id);
      };
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func resendCheck(state: State.BroadcastState) {
    for (event in Map.vals(state.events)) {
      if (event.numberOfAttempts < Const.RESEND_ATTEMPTS_LIMIT and Map.size(event.subscribers) > 0 and event.nextBroadcastTime <= time()) {
        Set.add(state.broadcastQueue, nhash, event.id);
      };
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func broadcast(state: State.BroadcastState): async* () {
    if (not state.broadcastActive) try {
      state.broadcastActive := true;

      for (eventId in Set.keys(state.broadcastQueue)) ignore do ?{
        await* broadcastEvent(state, Map.get(state.events, nhash, eventId)!);
      };

      state.broadcastActive := false;
    } catch (err) {
      state.broadcastActive := false;
    };
  };
};
