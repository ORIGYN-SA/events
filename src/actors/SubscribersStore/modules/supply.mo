import Buffer "mo:base/Buffer";
import Candy "mo:candy/types";
import CandyUtils "mo:candy_utils/CandyUtils";
import Const "../../../common/const";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import MigrationTypes "../../../migrations/types";
import Prim "mo:prim";
import Set "mo:map/Set";

module {
  let State = MigrationTypes.Current;

  let { get } = CandyUtils;

  let { nhash; thash; phash; lhash } = Map;

  let { nat8ToNat } = Prim;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type SubscribersBatchOptions = {
    from: ?Principal;
    rateSeed: Nat;
    listenersSeed: Nat;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.SubscribersStoreState, deployer: Principal): {
    supplySubscribersBatch: (caller: Principal, eventName: Text, payload: Candy.CandyValue, options: SubscribersBatchOptions) -> [(Principal, Principal)];
  } = object {
    let { subscribers; subscriptions } = state;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func supplySubscribersBatch(caller: Principal, eventName: Text, payload: Candy.CandyValue, options: SubscribersBatchOptions): [(Principal, Principal)] {
      if (caller != deployer) Debug.trap(Errors.PERMISSION_DENIED);

      let result = Buffer.Buffer<(Principal, Principal)>(0);

      ignore do ?{
        let subscriptionGroup = Map.get(subscriptions, thash, eventName)!;

        let subscriberIdsIter = if (options.from != null) Map.keysFrom(subscriptionGroup, phash, options.from!) else Map.keys(subscriptionGroup);

        label subscribersBatch for (subscriberId in subscriberIdsIter) ignore do ?{
          let subscriber = Map.get(subscribers, phash, subscriberId)!;
          let subscription = Map.get(subscriptionGroup, phash, subscriberId)!;

          if (options.rateSeed % 100 <= nat8ToNat(subscription.rate)) {
            if (subscription.filterPath == null or get(payload, subscription.filterPath!) != #Bool(false)) {
              let listenersSize = subscriber.confirmedListeners.size();

              result.add(subscriberId, subscriber.confirmedListeners[options.listenersSeed % listenersSize]);

              if (result.size() >= Const.SUBSCRIBERS_BATCH_SIZE) break subscribersBatch;
            };
          };
        };
      };

      return result.toArray();
    };
  };
};
