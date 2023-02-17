import Errors "../../../common/errors";
import Map "mo:map/Map";
import Principal "mo:base/Principal";
import PublishersStore "../../PublishersStore/main";
import Info "../../PublishersStore/modules/info";
import { take } "../../../utils/misc";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type PublisherInfoResponse = Info.PublisherInfoResponse;

  public type PublisherInfoParams = Info.PublisherInfoParams;

  public type PublisherInfoFullParams = (caller: Principal, state: State.PublishersIndexState, params: PublisherInfoParams);

  public func getPublisherInfo((caller, state, (publisherId, options)): PublisherInfoFullParams): async* PublisherInfoResponse {
    let publisherStoreId = take(Map.get(state.publishersLocation, phash, publisherId), Errors.PUBLISHER_NOT_FOUND);

    let publishersStore = actor(Principal.toText(publisherStoreId)):PublishersStore.PublishersStore;

    return await publishersStore.getPublisherInfo(publisherId, options);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type PublicationInfoResponse = Info.PublicationInfoResponse;

  public type PublicationInfoParams = Info.PublicationInfoParams;

  public type PublicationInfoFullParams = (caller: Principal, state: State.PublishersIndexState, params: PublicationInfoParams);

  public func getPublicationInfo((caller, state, (publisherId, eventName, options)): PublicationInfoFullParams): async* PublicationInfoResponse {
    let publisherStoreId = take(Map.get(state.publishersLocation, phash, publisherId), Errors.PUBLISHER_NOT_FOUND);

    let publishersStore = actor(Principal.toText(publisherStoreId)):PublishersStore.PublishersStore;

    return await publishersStore.getPublicationInfo(publisherId, eventName, options);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type PublicationStatsResponse = Info.PublicationStatsResponse;

  public type PublicationStatsParams = Info.PublicationStatsParams;

  public type PublicationStatsFullParams = (caller: Principal, state: State.PublishersIndexState, params: PublicationStatsParams);

  public func getPublicationStats((caller, state, (publisherId, options)): PublicationStatsFullParams): async* PublicationStatsResponse {
    let publisherStoreId = take(Map.get(state.publishersLocation, phash, publisherId), Errors.PUBLISHER_NOT_FOUND);

    let publishersStore = actor(Principal.toText(publisherStoreId)):PublishersStore.PublishersStore;

    return await publishersStore.getPublicationStats(publisherId, options);
  };
};
