import Map "mo:map/Map";
import MigrationTypes "../migrations/types";
import Set "mo:map/Set";
import Utils "../utils/misc";

module {
  let State = MigrationTypes.Current;

  let { pthash } = Utils;

  let { nhash; thash; phash; lhash; calcHash } = Map;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.State, deployer: Principal): {
    removeEventCascade: (eventId: Nat) -> ();
    removeSubscriberCascade: (subscriberId: Principal) -> ();
  } = object {
    let { subscribers; subscriptions; publishers; publications; events } = state;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func removeEventCascade(eventId: Nat) {
      ignore do ?{
        let event = Map.remove(events, nhash, eventId)!;
        let eventName = event.eventName;

        for (subscriberId in Set.keys(event.subscribers)) ignore do ?{
          let subscription = Map.get(subscriptions, pthash, (subscriberId, eventName))!;

          Set.delete(subscription.events, nhash, eventId);
        };
      };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func removeSubscriberCascade(subscriberId: Principal) {
      ignore do ?{
        let subscriberIdHash = calcHash(phash, subscriberId);
        let subscriber = Map.remove(subscribers, subscriberIdHash, subscriberId)!;

        for (eventName in Set.keys(subscriber.subscriptions)) ignore do ?{
          let subscription = Map.remove(subscriptions, pthash, (subscriberId, eventName))!;

          for (eventId in Set.keys(subscription.events)) ignore do ?{
            let event = Map.get(events, nhash, eventId)!;

            Set.delete(event.subscribers, subscriberIdHash, subscriberId);

            if (Set.size(event.subscribers) == 0) removeEventCascade(eventId);
          };
        };
      };
    };
  };
};
