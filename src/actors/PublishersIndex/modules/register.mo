import Errors "../../../common/errors";
import Map "mo:map/Map";
import Principal "mo:base/Principal";
import PublishersStore "../../PublishersStore/main";
import Register "../../PublishersStore/modules/register";
import { take; takeChain } "../../../utils/misc";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type PublisherResponse = Register.PublisherResponse;

  public type PublisherParams = (options: ?Register.PublisherOptions);

  public type PublisherFullParams = (caller: Principal, state: State.PublishersIndexState, params: PublisherParams);

  public func registerPublisher((caller, state, (options)): PublisherFullParams): async* PublisherResponse {
    let publisherStoreId = takeChain(
      Map.get(state.publishersLocation, phash, caller),
      state.publishersStoreId,
      Errors.NO_PUBLISHERS_STORE_CANISTERS,
    );

    let publishersStore = actor(Principal.toText(publisherStoreId)):PublishersStore.PublishersStore;

    let response = await publishersStore.registerPublisher(caller, options);

    Map.set(state.publishersLocation, phash, caller, publisherStoreId);

    return response;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type PublicationResponse = Register.PublicationResponse;

  public type PublicationParams = (eventName: Text, options: ?Register.PublicationOptions);

  public type PublicationFullParams = (caller: Principal, state: State.PublishersIndexState, params: PublicationParams);

  public func registerPublication((caller, state, (eventName, options)): PublicationFullParams): async* PublicationResponse {
    let publisherStoreId = takeChain(
      Map.get(state.publishersLocation, phash, caller),
      state.publishersStoreId,
      Errors.NO_PUBLISHERS_STORE_CANISTERS,
    );

    let publishersStore = actor(Principal.toText(publisherStoreId)):PublishersStore.PublishersStore;

    let response = await publishersStore.registerPublication(caller, eventName, options);

    Map.set(state.publishersLocation, phash, caller, publisherStoreId);

    return response;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type RemovePublicationResponse = Register.RemovePublicationResponse;

  public type RemovePublicationParams = (eventName: Text, options: ?Register.RemovePublicationOptions);

  public type RemovePublicationFullParams = (caller: Principal, state: State.PublishersIndexState, params: RemovePublicationParams);

  public func removePublication((caller, state, (eventName, options)): RemovePublicationFullParams): async* RemovePublicationResponse {
    let publisherStoreId = take(Map.get(state.publishersLocation, phash, caller), Errors.PUBLISHER_NOT_FOUND);

    let publishersStore = actor(Principal.toText(publisherStoreId)):PublishersStore.PublishersStore;

    return await publishersStore.removePublication(caller, eventName, options);
  };
};
