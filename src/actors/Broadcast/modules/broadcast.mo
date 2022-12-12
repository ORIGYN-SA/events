import Const "../../../common/const";
import Map "mo:map/Map";
import MigrationTypes "../../../migrations/types";
import Prim "mo:prim";
import Principal "mo:base/Principal";
import Set "mo:map/Set";
import Types "../../../common/types";
import Utils "../../../utils/misc";

module {
  let State = MigrationTypes.Current;

  let { nat8ToNat64 } = Utils;

  let { nhash; thash; phash; lhash } = Map;

  let { time } = Prim;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.BroadcastState, deployer: Principal): {
    broadcast: () -> async ();
  } = object {
    let { events; broadcastQueue } = state;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    func broadcastEvent(event: State.Event): async () {
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

                subscription.numberOfNotifications +%= 1;

                if (numberOfAttempts > 0) subscription.numberOfResendNotifications +%= 1;

                let publicationGroup = Map.get(publications, thash, event.eventName)!;
                let publication = Map.get(publicationGroup, phash, event.publisherId)!;

                publication.numberOfNotifications +%= 1;

                if (numberOfAttempts > 0) publication.numberOfResendNotifications +%= 1;
              };
            };

            Map.set(event.subscribers, phash, subscriberId, numberOfAttempts +% 1);

            notificationsCount +%= 1;

            if (notificationsCount % Const.BROADCAST_BATCH_SIZE == 0) break broadcastBatch;
          };

          iterActive := false;
        };

        event.numberOfAttempts +%= 1;
        event.nextBroadcastTime := eventBroadcastStartTime + Const.RESEND_DELAY * 2 ** nat8ToNat64(event.numberOfAttempts -% 1);
      } else {
        Map.delete(events, nhash, event.id);

        for (subscriberId in Map.keys(event.subscribers)) ignore do ?{
          let subscriptionGroup = Map.get(subscriptions, thash, event.eventName)!;
          let subscription = Map.get(subscriptionGroup, phash, subscriberId)!;

          Set.delete(subscription.events, nhash, event.id);
        };
      };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func resendCheck() {
      for (event in Map.vals(events)) if (event.nextBroadcastTime <= time()) Set.add(broadcastQueue, nhash, event.id);
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func broadcast(): async () {
      if (not state.broadcastActive) try {
        state.broadcastActive := true;

        for (eventId in Set.keys(broadcastQueue)) ignore do ?{ await broadcastEvent(Map.get(events, nhash, eventId)!) };

        state.broadcastActive := false;
      } catch (err) {
        state.broadcastActive := false;
      };
    };
  };
};
