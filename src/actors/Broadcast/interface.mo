import Config "./modules/config";
import Confirm "./modules/confirm";
import Info "./modules/info";
import Publish "./modules/publish";
import Request "./modules/request";

module {
  public type Broadcast = actor {
    addSubscribersStoreIds: shared (params: Config.SubscribersStoreIdsParams) -> async Config.SubscribersStoreIdsResponse;
    confirmEventProcessed: shared (params: Confirm.ConfirmEventParams) -> async Confirm.ConfirmEventResponse;
    getEventInfo: query (params: Info.EventInfoParams) -> async Info.EventInfoResponse;
    publish: shared (params: Publish.PublishParams) -> async Publish.PublishResponse;
    requestEvents: shared (params: Request.RequestEventsParams) -> async Request.RequestEventsResponse;
    addCycles: query () -> async Nat;
  };
};
