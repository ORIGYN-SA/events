import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Set "mo:map/Set";
import { n32hash; n64hash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type ConfirmListenerResponse = {
    confirmed: Bool;
  };

  public type ConfirmListenerParams = (listenerId: Principal, subscriberId: Principal);

  public type ConfirmListenerFullParams = (caller: Principal, state: State.SubscribersStoreState, params: ConfirmListenerParams);

  public func confirmListener((caller, state, (listenerId, subscriberId)): ConfirmListenerFullParams): ConfirmListenerResponse {
    if (caller != state.subscribersIndexId) Debug.trap(Errors.PERMISSION_DENIED);
    if (subscriberId == listenerId) Debug.trap(Errors.SELF_LISTENER);

    var confirmed = false;

    ignore do ?{
      let subscriber = Map.get(state.subscribers, phash, subscriberId)!;

      if (Set.has(subscriber.listeners, phash, listenerId)) {
        if (Array.find<Principal>(subscriber.confirmedListeners, func(item) = item == listenerId) == null) {
          subscriber.confirmedListeners := Array.append(subscriber.confirmedListeners, [listenerId]);

          confirmed := true;
        };
      };
    };

    return { confirmed };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type RemoveListenerResponse = {
    removed: Bool;
  };

  public type RemoveListenerParams = (listenerId: Principal, subscriberId: Principal);

  public type RemoveListenerFullParams = (caller: Principal, state: State.SubscribersStoreState, params: RemoveListenerParams);

  public func removeListener((caller, state, (listenerId, subscriberId)): RemoveListenerFullParams): RemoveListenerResponse {
    if (caller != state.subscribersIndexId) Debug.trap(Errors.PERMISSION_DENIED);
    if (subscriberId == listenerId) Debug.trap(Errors.SELF_LISTENER);

    var removed = false;

    ignore do ?{
      let subscriber = Map.get(state.subscribers, phash, subscriberId)!;

      if (Set.has(subscriber.listeners, phash, listenerId)) {
        let confirmedListenersSize = subscriber.confirmedListeners.size();

        subscriber.confirmedListeners := Array.filter<Principal>(subscriber.confirmedListeners, func(item) = item != listenerId);

        removed := subscriber.confirmedListeners.size() != confirmedListenersSize;
      };
    };

    return { removed };
  };
};
