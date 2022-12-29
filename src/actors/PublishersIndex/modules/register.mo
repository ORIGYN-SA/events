import Errors "../../../common/errors";
import Map "mo:map/Map";
import Principal "mo:base/Principal";
import PublishersStore "../../PublishersStore/main";
import Register "../../PublishersStore/modules/register";
import Set "mo:map/Set";
import { take; takeChain } "../../../utils/misc";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type PublisherResponse = Register.PublisherResponse;

  public type PublisherParams = Register.PublisherParams;

  public type PublisherFullParams = (caller: Principal, state: State.PublishersIndexState, params: PublisherParams);

  public func registerPublisher((caller, state, (publisherId, options)): PublisherFullParams): async PublisherResponse {
    let publisherStoreId = takeChain(
      Map.get(state.publishersLocation, phash, publisherId),
      Set.peekFront(state.publishersStoreIds),
      Errors.NO_PUBLISHERS_STORE_CANISTERS,
    );

    let publishersStore = actor(Principal.toText(publisherStoreId)):PublishersStore.PublishersStore;

    let response = await publishersStore.registerPublisher(publisherId, options);

    Map.set(state.publishersLocation, phash, publisherId, publisherStoreId);

    return response;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type PublicationResponse = Register.PublicationResponse;

  public type PublicationParams = Register.PublicationParams;

  public type PublicationFullParams = (caller: Principal, state: State.PublishersIndexState, params: PublicationParams);

  public func registerPublication((caller, state, (publisherId, eventName, options)): PublicationFullParams): async PublicationResponse {
    let publisherStoreId = takeChain(
      Map.get(state.publishersLocation, phash, publisherId),
      Set.peekFront(state.publishersStoreIds),
      Errors.NO_PUBLISHERS_STORE_CANISTERS,
    );

    let publishersStore = actor(Principal.toText(publisherStoreId)):PublishersStore.PublishersStore;

    let response = await publishersStore.registerPublication(publisherId, eventName, options);

    Map.set(state.publishersLocation, phash, publisherId, publisherStoreId);

    return response;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type RemovePublicationResponse = Register.RemovePublicationResponse;

  public type RemovePublicationParams = Register.RemovePublicationParams;

  public type RemovePublicationFullParams = (caller: Principal, state: State.PublishersIndexState, params: RemovePublicationParams);

  public func removePublication((caller, state, (publisherId, eventName, options)): RemovePublicationFullParams): async RemovePublicationResponse {
    let publisherStoreId = take(Map.get(state.publishersLocation, phash, publisherId), Errors.PUBLISHER_NOT_FOUND);

    let publishersStore = actor(Principal.toText(publisherStoreId)):PublishersStore.PublishersStore;

    return await publishersStore.removePublication(publisherId, eventName, options);
  };
};
