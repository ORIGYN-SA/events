import Config "./modules/config";
import Info "./modules/info";
import Listen "./modules/listen";
import Stats "./modules/stats";
import Subscribe "./modules/subscribe";
import Supply "./modules/supply";

module {
  public type SubscribersStore = actor {
    addBroadcastIds: shared (params: Config.BroadcastIdsParams) -> async Config.BroadcastIdsResponse;
    getSubscriberInfo: query (params: Info.SubscriberInfoParams) -> async Info.SubscriberInfoResponse;
    getSubscriptionInfo: query (params: Info.SubscriptionInfoParams) -> async Info.SubscriptionInfoResponse;
    getSubscriptionStats: query (params: Info.SubscriptionStatsParams) -> async Info.SubscriptionStatsResponse;
    confirmListener: shared (params: Listen.ConfirmListenerParams) -> async Listen.ConfirmListenerResponse;
    removeListener: shared (params: Listen.RemoveListenerParams) -> async Listen.RemoveListenerResponse;
    consumeSubscriptionStats: shared (params: Stats.ConsumeStatsParams) -> async Stats.ConsumeStatsResponse;
    registerSubscriber: shared (params: Subscribe.SubscriberParams) -> async Subscribe.SubscriberResponse;
    subscribe: shared (params: Subscribe.SubscriptionParams) -> async Subscribe.SubscriptionResponse;
    unsubscribe: shared (params: Subscribe.UnsubscribeParams) -> async Subscribe.UnsubscribeResponse;
    supplySubscribersBatch: query (params: Supply.SubscribersBatchParams) -> async Supply.SubscribersBatchResponse;
    addCycles: query () -> async Nat;
  };
};
