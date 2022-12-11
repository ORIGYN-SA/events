import Debug "mo:base/Debug";
import Errors "./errors";
import Map "mo:map/Map";
import MigrationTypes "../migrations/types";
import Option "mo:base/Option";
import Set "mo:map/Set";
import State "../migrations/00-01-00-initial/types";

module {
  let State = MigrationTypes.Current;

  let { nhash; thash; phash; lhash } = Map;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type RemoveListenerResponse = {
    prevActiveSubscriberId: ?Principal;
    prevSubscriberId: ?Principal;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type ConfirmListenerResponse = {
    activeSubscriberId: ?Principal;
    prevActiveSubscriberId: ?Principal;
    prevSubscriberId: ?Principal;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.State, deployer: Principal): {
    removeListener: (caller: Principal) -> RemoveListenerResponse;
    confirmListener: (caller: Principal, subscriberId: Principal) -> ConfirmListenerResponse;
  } = object {
    let { subscribers; confirmedListeners } = state;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func removeListener(caller: Principal): RemoveListenerResponse {
      var prevActiveSubscriberId = null:?Principal;

      let prevSubscriberId = Map.remove(confirmedListeners, phash, caller);

      ignore do ?{
        let prevSubscriber = Map.get(subscribers, phash, prevSubscriberId!)!;

        if (Set.remove(prevSubscriber.confirmedListeners, phash, caller)) prevActiveSubscriberId := ?prevSubscriber.id;
      };

      return { prevActiveSubscriberId; prevSubscriberId };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func confirmListener(caller: Principal, subscriberId: Principal): ConfirmListenerResponse {
      if (caller == subscriberId) Debug.trap(Errors.SELF_LISTENER);

      var activeSubscriberId = null:?Principal;

      let { prevActiveSubscriberId; prevSubscriberId } = removeListener(caller);

      Map.set(confirmedListeners, phash, caller, subscriberId);

      ignore do ?{
        let subscriber = Map.get(subscribers, phash, subscriberId)!;

        if (Set.has(subscriber.listeners, phash, caller)) {
          activeSubscriberId := ?subscriber.id;

          Set.add(subscriber.confirmedListeners, phash, caller);
        };
      };

      return { activeSubscriberId; prevActiveSubscriberId; prevSubscriberId };
    };
  };
};
