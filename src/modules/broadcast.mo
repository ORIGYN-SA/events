import Cascade "./cascade";
import Const "./const";
import Map "mo:map/Map";
import MigrationTypes "../migrations/types";
import Prim "mo:prim";
import Principal "mo:base/Principal";
import Set "mo:map/Set";
import Subscribe "./subscribe";
import Utils "../utils/misc";

module {
  let State = MigrationTypes.Current;

  let { nat8ToNat64; pthash } = Utils;

  let { nhash; thash; phash; lhash } = Map;

  let { time } = Prim;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.State, deployer: Principal): {
    broadcast: () -> async ();
  } = object {
    let { removeEventCascade } = Cascade.init(state, deployer);

    let { subscribers; subscriptions; events } = state;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    func broadcastEvent(event: State.Event): async () {
      Prim.debugPrint(debug_show("Processing event", event.id));

      if (event.numberOfAttempts < Const.RESEND_ATTEMPTS_LIMIT) {
        let subscribersIter = Map.entries(event.subscribers);
        let eventBroadcastStartTime = time();
        var notificationsCount = 0:Nat8;
        var iterActive = true;

        while (iterActive) await async label broadcastBatch {
          for ((subscriberId, numberOfAttempts) in subscribersIter) if (numberOfAttempts <= event.numberOfAttempts) ignore do ?{
            let subscription = Map.get(subscriptions, pthash, (subscriberId, event.eventName))!;

            if (subscription.active and not subscription.stopped) {
              let subscriberActor: Subscribe.SubscriberActor = actor(Principal.toText(subscriberId));

              subscriberActor.handleEvent(event.id, event.publisherId, event.eventName, event.payload);

              Map.set(event.subscribers, phash, subscriberId, numberOfAttempts +% 1);
              Set.delete(event.resendRequests, phash, subscriberId);

              notificationsCount +%= 1;

              if (notificationsCount % Const.BROADCAST_BATCH_SIZE == 0) break broadcastBatch;
            };
          };

          iterActive := false;
        };

        event.numberOfAttempts +%= 1;
        event.nextResendTime := eventBroadcastStartTime + Const.RESEND_DELAY * 2 ** nat8ToNat64(event.numberOfAttempts -% 1);
      } else {
        removeEventCascade(event.id);
      };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    func broadcastResendRequests(event: State.Event): async () {
      let subscribersIter = Set.keys(event.resendRequests);
      var notificationsCount = 0:Nat8;
      var iterActive = true;

      while (iterActive) await async label broadcastBatch {
        for (subscriberId in subscribersIter) {
          let subscriberActor: Subscribe.SubscriberActor = actor(Principal.toText(subscriberId));

          subscriberActor.handleEvent(event.id, event.publisherId, event.eventName, event.payload);

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

        for (event in Map.vals(events)) if (broadcastStartTime >= event.nextResendTime) await broadcastEvent(event);
        for (event in Map.vals(events)) if (Set.size(event.resendRequests) > 0) await broadcastResendRequests(event);

        state.broadcastActive := false;
        state.nextBroadcastTime := broadcastStartTime + Const.BROADCAST_DELAY;
      } catch (err) {
        state.broadcastActive := false;
      };
    };
  };
};
