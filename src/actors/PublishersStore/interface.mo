import Config "./modules/config";
import Info "./modules/info";
import Register "./modules/register";
import Stats "./modules/stats";
import Supply "./modules/supply";

module {
  public type PublishersStore = actor {
    addBroadcastIds: shared (params: Config.BroadcastIdsParams) -> async Config.BroadcastIdsResponse;
    getPublisherInfo: query (params: Info.PublisherInfoParams) -> async Info.PublisherInfoResponse;
    getPublicationInfo: query (params: Info.PublicationInfoParams) -> async Info.PublicationInfoResponse;
    getPublicationStats: query (params: Info.PublicationStatsParams) -> async Info.PublicationStatsResponse;
    registerPublisher: shared (params: Register.PublisherParams) -> async Register.PublisherResponse;
    registerPublication: shared (params: Register.PublicationParams) -> async Register.PublicationResponse;
    removePublication: shared (params: Register.RemovePublicationParams) -> async Register.RemovePublicationResponse;
    consumePublicationStats: shared (params: Stats.ConsumeStatsParams) -> async Stats.ConsumeStatsResponse;
    supplyPublicationData: query (params: Supply.PublicationDataParams) -> async Supply.PublicationDataResponse;
  };
};
