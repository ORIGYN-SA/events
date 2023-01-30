import Config "./modules/config";
import Location "./modules/location";
import Subscribe "./modules/subscribe";
import Transfer "./modules/transfer";

module {
  public type SubscribersIndex = actor {
    setSubscribersStoreId: shared (params: Config.SubscribersStoreIdParams) -> async Config.SubscribersStoreIdResponse;
    addBroadcastIds: shared (params: Config.BroadcastIdsParams) -> async Config.BroadcastIdsResponse;
    getSubscriberLocation: query (params: Location.GetLocationParams) -> async Location.GetLocationResponse;
    registerSubscriber: shared (params: Subscribe.SubscriberParams) -> async Subscribe.SubscriberResponse;
    subscribe: shared (params: Subscribe.SubscriptionParams) -> async Subscribe.SubscriptionResponse;
    unsubscribe: shared (params: Subscribe.UnsubscribeParams) -> async Subscribe.UnsubscribeResponse;
    transferSubscriptionStats: shared (params: Transfer.TransferStatsParams) -> async Transfer.TransferStatsResponse;
  };
};
