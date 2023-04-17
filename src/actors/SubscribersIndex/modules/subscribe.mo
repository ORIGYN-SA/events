import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Principal "mo:base/Principal";
import Subscribe "../../SubscribersStore/modules/subscribe";
import SubscribersStore "../../SubscribersStore/main";
import { takeChain } "../../../utils/misc";
import { n32hash; n64hash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type SubscriberResponse = Subscribe.SubscriberResponse;

  public type SubscriberParams = (options: ?Subscribe.SubscriberOptions);

  public type SubscriberFullParams = (caller: Principal, state: State.SubscribersIndexState, params: SubscriberParams);

  public func registerSubscriber((caller, state, (options)): SubscriberFullParams): async* SubscriberResponse {
    let subscriberStoreId = takeChain(
      Map.get(state.subscribersLocation, phash, caller),
      state.subscribersStoreId,
      Errors.NO_SUBSCRIBERS_STORE_CANISTERS,
    );

    let subscribersStore = actor(Principal.toText(subscriberStoreId)):SubscribersStore.SubscribersStore;

    let response = await subscribersStore.registerSubscriber(caller, options);

    Map.set(state.subscribersLocation, phash, caller, subscriberStoreId);

    return response;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type SubscriptionResponse = Subscribe.SubscriptionResponse;

  public type SubscriptionParams = (eventName: Text, options: ?Subscribe.SubscriptionOptions);

  public type SubscriptionFullParams = (caller: Principal, state: State.SubscribersIndexState, params: SubscriptionParams);

  public func subscribe((caller, state, (eventName, options)): SubscriptionFullParams): async* SubscriptionResponse {
    let subscriberStoreId = takeChain(
      Map.get(state.subscribersLocation, phash, caller),
      state.subscribersStoreId,
      Errors.NO_SUBSCRIBERS_STORE_CANISTERS,
    );

    let subscribersStore = actor(Principal.toText(subscriberStoreId)):SubscribersStore.SubscribersStore;

    let response = await subscribersStore.subscribe(caller, eventName, options);

    Map.set(state.subscribersLocation, phash, caller, subscriberStoreId);

    return response;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type UnsubscribeResponse = Subscribe.UnsubscribeResponse;

  public type UnsubscribeParams = (eventName: Text, options: ?Subscribe.UnsubscribeOptions);

  public type UnsubscribeFullParams = (caller: Principal, state: State.SubscribersIndexState, params: UnsubscribeParams);

  public func unsubscribe((caller, state, (eventName, options)): UnsubscribeFullParams): async* UnsubscribeResponse {
    let ?subscriberStoreId = Map.get(state.subscribersLocation, phash, caller) else Debug.trap(Errors.SUBSCRIBER_NOT_FOUND);

    let subscribersStore = actor(Principal.toText(subscriberStoreId)):SubscribersStore.SubscribersStore;

    return await subscribersStore.unsubscribe(caller, eventName, options);
  };
};
