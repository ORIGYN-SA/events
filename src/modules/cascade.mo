import Map "mo:map/Map";
import MigrationTypes "../migrations/types";
import Set "mo:map/Set";

module {
  let State = MigrationTypes.Current;

  let { nhash; thash; phash; lhash } = Map;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.State, deployer: Principal): {
    removeEventCascade: (eventId: Nat) -> ();
    removeSubscriberCascade: (subscriberId: Principal) -> ();
  } = object {
    let { subscribers; subscriptions; events } = state;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func removeEventCascade(eventId: Nat) {
      ignore do ?{
        let event = Map.remove(events, nhash, eventId)!;

        for (subscriberId in Map.keys(event.subscribers)) ignore do ?{
          let subscriptionGroup = Map.get(subscriptions, thash, event.eventName)!;
          let subscription = Map.get(subscriptionGroup, phash, subscriberId)!;

          Set.delete(subscription.events, nhash, eventId);
        };
      };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func removeSubscriberCascade(subscriberId: Principal) {
      ignore do ?{
        let subscriber = Map.remove(subscribers, phash, subscriberId)!;

        for (eventName in Set.keys(subscriber.subscriptions)) ignore do ?{
          let subscriptionGroup = Map.get(subscriptions, thash, eventName)!;
          let subscription = Map.remove(subscriptionGroup, phash, subscriberId)!;

          if (Map.size(subscriptionGroup) == 0) Map.delete(subscriptions, thash, eventName);

          for (eventId in Set.keys(subscription.events)) ignore do ?{
            let event = Map.get(events, nhash, eventId)!;

            Set.delete(event.resendRequests, phash, subscriberId);
            Map.delete(event.subscribers, phash, subscriberId);

            if (Map.size(event.subscribers) == 0) removeEventCascade(eventId);
          };
        };
      };
    };
  };
};
