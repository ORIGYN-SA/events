import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Principal "mo:base/Principal";
import SubscribersStore "../../SubscribersStore/main";
import Info "../../SubscribersStore/modules/info";
import { n32hash; n64hash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type SubscriberInfoResponse = Info.SubscriberInfoResponse;

  public type SubscriberInfoParams = (options: ?Info.SubscriberInfoOptions);

  public type SubscriberInfoFullParams = (caller: Principal, state: State.SubscribersIndexState, params: SubscriberInfoParams);

  public func getSubscriberInfo((caller, state, (options)): SubscriberInfoFullParams): async* SubscriberInfoResponse {
    let ?subscriberStoreId = Map.get(state.subscribersLocation, phash, caller) else Debug.trap(Errors.SUBSCRIBER_NOT_FOUND);

    let subscribersStore = actor(Principal.toText(subscriberStoreId)):SubscribersStore.SubscribersStore;

    return await subscribersStore.getSubscriberInfo(caller, options);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type SubscriptionInfoResponse = Info.SubscriptionInfoResponse;

  public type SubscriptionInfoParams = (eventName: Text);

  public type SubscriptionInfoFullParams = (caller: Principal, state: State.SubscribersIndexState, params: SubscriptionInfoParams);

  public func getSubscriptionInfo((caller, state, (eventName)): SubscriptionInfoFullParams): async* SubscriptionInfoResponse {
    let ?subscriberStoreId = Map.get(state.subscribersLocation, phash, caller) else Debug.trap(Errors.SUBSCRIBER_NOT_FOUND);

    let subscribersStore = actor(Principal.toText(subscriberStoreId)):SubscribersStore.SubscribersStore;

    return await subscribersStore.getSubscriptionInfo(caller, eventName);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type SubscriptionStatsResponse = Info.SubscriptionStatsResponse;

  public type SubscriptionStatsParams = (options: ?Info.SubscriptionStatsOptions);

  public type SubscriptionStatsFullParams = (caller: Principal, state: State.SubscribersIndexState, params: SubscriptionStatsParams);

  public func getSubscriptionStats((caller, state, (options)): SubscriptionStatsFullParams): async* SubscriptionStatsResponse {
    let ?subscriberStoreId = Map.get(state.subscribersLocation, phash, caller) else Debug.trap(Errors.SUBSCRIBER_NOT_FOUND);

    let subscribersStore = actor(Principal.toText(subscriberStoreId)):SubscribersStore.SubscribersStore;

    return await subscribersStore.getSubscriptionStats(caller, options);
  };
};
