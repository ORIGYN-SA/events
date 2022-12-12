import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import MigrationTypes "../../../migrations/types";
import Set "mo:map/Set";

module {
  let State = MigrationTypes.Current;

  let { nhash; thash; phash; lhash } = Map;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type EventsRequest = {
    subscriberId: Principal;
    eventName: Text;
    from: ?Nat64;
    to: ?Nat64;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.BroadcastState, deployer: Principal): {
    requestEvents: (caller: Principal, missedOnly: Bool, requests: [EventsRequest]) -> ();
  } = object {
    let { events; broadcastQueue } = state;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func requestEvents(caller: Principal, missedOnly: Bool, requests: [EventsRequest]) {
      if (caller != deployer) Debug.trap(Errors.PERMISSION_DENIED);

      let eventNames = Set.fromIterMap<Text, EventsRequest>(requests.vals(), thash, func(item) = ?item.eventName);

      for (event in Map.vals(events)) if (Set.has(eventNames, thash, event.eventName)) {
        for ({ subscriberId; eventName; from; to } in requests.vals()) ignore do ?{
          if (
            event.eventName == eventName and
            (not missedOnly or Map.has(event.subscribers, phash, subscriberId)) and
            (from == null or event.createdAt < from!) and
            (to == null or event.createdAt > to!)
          ) {
            Set.add(event.eventRequests, phash, subscriberId);
            Set.add(broadcastQueue, nhash, event.id);
          };
        };
      };
    };
  };
};
