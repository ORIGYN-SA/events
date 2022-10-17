import Candy "mo:candy/types";
import Const "./const";
import Map "mo:map/Map";
import MigrationTypes "../migrations/types";
import Prim "mo:prim";
import Principal "mo:base/Principal";
import Set "mo:map/Set";
import Utils "../utils/misc";

module {
  let State = MigrationTypes.Current;

  let { nat8ToNat64 } = Utils;

  let { nhash; thash; phash; lhash } = Map;

  let { time } = Prim;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type ListenerActor = actor {
    handleEvent: (eventId: Nat, publisherId: Principal, eventName: Text, payload: Candy.CandyValue) -> ();
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.State, deployer: Principal): {
    broadcast: () -> async ();
  } = object {
    let { publications; subscribers; subscriptions; events } = state;

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
                let listenerActor = actor(Principal.toText(listenerId)):ListenerActor;

                Set.add(subscriber.confirmedListeners, phash, listenerId);
                Set.delete(event.resendRequests, phash, subscriberId);

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

    func broadcastResendRequests(event: State.Event): async () {
      let subscribersIter = Set.keys(event.resendRequests);
      var notificationsCount = 0:Nat8;
      var iterActive = true;

      while (iterActive) await async label broadcastBatch {
        for (subscriberId in subscribersIter) {
          ignore do ?{
            let subscriptionGroup = Map.get(subscriptions, thash, event.eventName)!;
            let subscription = Map.get(subscriptionGroup, phash, subscriberId)!;
            let subscriber = Map.get(subscribers, phash, subscriberId)!;
            let listenerId = Set.popFront(subscriber.confirmedListeners)!;
            let listenerActor = actor(Principal.toText(listenerId)):ListenerActor;

            Set.add(subscriber.confirmedListeners, phash, listenerId);

            listenerActor.handleEvent(event.id, event.publisherId, event.eventName, event.payload);

            subscription.numberOfNotifications +%= 1;
            subscription.numberOfRequestedNotifications +%= 1;

            let publicationGroup = Map.get(publications, thash, event.eventName)!;
            let publication = Map.get(publicationGroup, phash, event.publisherId)!;

            publication.numberOfNotifications +%= 1;
            publication.numberOfRequestedNotifications +%= 1;
          };

          Set.delete(event.resendRequests, phash, subscriberId);

          notificationsCount +%= 1;

          if (notificationsCount % Const.BROADCAST_BATCH_SIZE == 0) break broadcastBatch;
        };

        iterActive := false;
      };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func broadcast(): async () {
      let broadcastStartTime = time();

      if (not state.broadcastActive and broadcastStartTime >= state.nextBroadcastTime) try {
        state.broadcastActive := true;

        for (event in Map.vals(events)) if (broadcastStartTime >= event.nextBroadcastTime) await broadcastEvent(event);
        for (event in Map.vals(events)) if (Set.size(event.resendRequests) > 0) await broadcastResendRequests(event);

        state.broadcastActive := false;
        state.nextBroadcastTime := broadcastStartTime + Const.BROADCAST_DELAY;
      } catch (err) {
        state.broadcastActive := false;
      };
    };
  };
};
