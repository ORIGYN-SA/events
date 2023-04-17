import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Principal "mo:base/Principal";
import PublishersStore "../../PublishersStore/main";
import Info "../../PublishersStore/modules/info";
import { n32hash; n64hash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type PublisherInfoResponse = Info.PublisherInfoResponse;

  public type PublisherInfoParams = (options: ?Info.PublisherInfoOptions);

  public type PublisherInfoFullParams = (caller: Principal, state: State.PublishersIndexState, params: PublisherInfoParams);

  public func getPublisherInfo((caller, state, (options)): PublisherInfoFullParams): async* PublisherInfoResponse {
    let ?publisherStoreId = Map.get(state.publishersLocation, phash, caller) else Debug.trap(Errors.PUBLISHER_NOT_FOUND);

    let publishersStore = actor(Principal.toText(publisherStoreId)):PublishersStore.PublishersStore;

    return await publishersStore.getPublisherInfo(caller, options);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type PublicationInfoResponse = Info.PublicationInfoResponse;

  public type PublicationInfoParams = (eventName: Text, options: ?Info.PublicationInfoOptions);

  public type PublicationInfoFullParams = (caller: Principal, state: State.PublishersIndexState, params: PublicationInfoParams);

  public func getPublicationInfo((caller, state, (eventName, options)): PublicationInfoFullParams): async* PublicationInfoResponse {
    let ?publisherStoreId = Map.get(state.publishersLocation, phash, caller) else Debug.trap(Errors.PUBLISHER_NOT_FOUND);

    let publishersStore = actor(Principal.toText(publisherStoreId)):PublishersStore.PublishersStore;

    return await publishersStore.getPublicationInfo(caller, eventName, options);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type PublicationStatsResponse = Info.PublicationStatsResponse;

  public type PublicationStatsParams = (options: ?Info.PublicationStatsOptions);

  public type PublicationStatsFullParams = (caller: Principal, state: State.PublishersIndexState, params: PublicationStatsParams);

  public func getPublicationStats((caller, state, (options)): PublicationStatsFullParams): async* PublicationStatsResponse {
    let ?publisherStoreId = Map.get(state.publishersLocation, phash, caller) else Debug.trap(Errors.PUBLISHER_NOT_FOUND);

    let publishersStore = actor(Principal.toText(publisherStoreId)):PublishersStore.PublishersStore;

    return await publishersStore.getPublicationStats(caller, options);
  };
};
