import Errors "../../../common/errors";
import Map "mo:map/Map";
import Principal "mo:base/Principal";
import SubscribersStore "../../SubscribersStore/main";
import Info "../../SubscribersStore/modules/info";
import { take } "../../../utils/misc";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type SubscriberInfoResponse = Info.SubscriberInfoResponse;

  public type SubscriberInfoParams = Info.SubscriberInfoParams;

  public type SubscriberInfoFullParams = (caller: Principal, state: State.SubscribersIndexState, params: SubscriberInfoParams);

  public func getSubscriberInfo((caller, state, (subscriberId, options)): SubscriberInfoFullParams): async* SubscriberInfoResponse {
    let subscriberStoreId = take(Map.get(state.subscribersLocation, phash, subscriberId), Errors.SUBSCRIBER_NOT_FOUND);

    let subscribersStore = actor(Principal.toText(subscriberStoreId)):SubscribersStore.SubscribersStore;

    return await subscribersStore.getSubscriberInfo(subscriberId, options);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type SubscriptionInfoResponse = Info.SubscriptionInfoResponse;

  public type SubscriptionInfoParams = Info.SubscriptionInfoParams;

  public type SubscriptionInfoFullParams = (caller: Principal, state: State.SubscribersIndexState, params: SubscriptionInfoParams);

  public func getSubscriptionInfo((caller, state, (subscriberId, eventName)): SubscriptionInfoFullParams): async* SubscriptionInfoResponse {
    let subscriberStoreId = take(Map.get(state.subscribersLocation, phash, subscriberId), Errors.SUBSCRIBER_NOT_FOUND);

    let subscribersStore = actor(Principal.toText(subscriberStoreId)):SubscribersStore.SubscribersStore;

    return await subscribersStore.getSubscriptionInfo(subscriberId, eventName);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type SubscriptionStatsResponse = Info.SubscriptionStatsResponse;

  public type SubscriptionStatsParams = Info.SubscriptionStatsParams;

  public type SubscriptionStatsFullParams = (caller: Principal, state: State.SubscribersIndexState, params: SubscriptionStatsParams);

  public func getSubscriptionStats((caller, state, (subscriberId, options)): SubscriptionStatsFullParams): async* SubscriptionStatsResponse {
    let subscriberStoreId = take(Map.get(state.subscribersLocation, phash, subscriberId), Errors.SUBSCRIBER_NOT_FOUND);

    let subscribersStore = actor(Principal.toText(subscriberStoreId)):SubscribersStore.SubscribersStore;

    return await subscribersStore.getSubscriptionStats(subscriberId, options);
  };
};
