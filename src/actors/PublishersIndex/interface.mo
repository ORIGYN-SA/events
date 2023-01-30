import Config "./modules/config";
import Location "./modules/location";
import Register "./modules/register";
import Transfer "./modules/transfer";

module {
  public type PublishersIndex = actor {
    setPublishersStoreId: shared (params: Config.PublishersStoreIdParams) -> async Config.PublishersStoreIdResponse;
    addBroadcastIds: shared (params: Config.BroadcastIdsParams) -> async Config.BroadcastIdsResponse;
    getPublisherLocation: query (params: Location.GetLocationParams) -> async Location.GetLocationResponse;
    registerPublisher: shared (params: Register.PublisherParams) -> async Register.PublisherResponse;
    registerPublication: shared (params: Register.PublicationParams) -> async Register.PublicationResponse;
    removePublication: shared (params: Register.RemovePublicationParams) -> async Register.RemovePublicationResponse;
    transferPublicationStats: shared (params: Transfer.TransferStatsParams) -> async Transfer.TransferStatsResponse;
  };
};
