import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import MigrationTypes "../../../migrations/types";
import Set "mo:map/Set";

module {
  let State = MigrationTypes.Current;

  let { nhash; thash; phash; lhash } = Map;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type ConfirmListenerResponse = {
    confirmed: Bool;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type RemoveListenerResponse = {
    removed: Bool;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.SubscribersStoreState, deployer: Principal): {
    confirmListener: (caller: Principal, listenerId: Principal, subscriberId: Principal) -> ConfirmListenerResponse;
    removeListener: (caller: Principal, listenerId: Principal, subscriberId: Principal) -> RemoveListenerResponse;
  } = object {
    let { subscribers } = state;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func confirmListener(caller: Principal, listenerId: Principal, subscriberId: Principal): ConfirmListenerResponse {
      if (caller != deployer) Debug.trap(Errors.PERMISSION_DENIED);
      if (subscriberId == listenerId) Debug.trap(Errors.SELF_LISTENER);

      var confirmed = false;

      ignore do ?{
        let subscriber = Map.get(subscribers, phash, subscriberId)!;

        if (Set.has(subscriber.listeners, phash, listenerId)) {
          if (Array.find<Principal>(subscriber.confirmedListeners, func(item) = item == listenerId) == null) {
            subscriber.confirmedListeners := Array.append(subscriber.confirmedListeners, [listenerId]);

            confirmed := true;
          };
        };
      };

      return { confirmed };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func removeListener(caller: Principal, listenerId: Principal, subscriberId: Principal): RemoveListenerResponse {
      if (caller != deployer) Debug.trap(Errors.PERMISSION_DENIED);
      if (subscriberId == listenerId) Debug.trap(Errors.SELF_LISTENER);

      var removed = false;

      ignore do ?{
        let subscriber = Map.get(subscribers, phash, subscriberId)!;

        if (Set.has(subscriber.listeners, phash, listenerId)) {
          let confirmedListenersSize = subscriber.confirmedListeners.size();

          subscriber.confirmedListeners := Array.filter<Principal>(subscriber.confirmedListeners, func(item) = item != listenerId);

          removed := subscriber.confirmedListeners.size() != confirmedListenersSize;
        };
      };

      return { removed };
    };
  };
};
