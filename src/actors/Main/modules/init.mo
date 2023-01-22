import Array "mo:base/Array";
import Broadcast "../../Broadcast/main";
import Const "../../../common/const";
import Cycles "mo:base/ExperimentalCycles";
import Iter "mo:base/Iter";
import Map "mo:map/Map";
import Principal "mo:base/Principal";
import PublishersIndex "../../PublishersIndex/main";
import PublishersStore "../../PublishersStore/main";
import SubscribersIndex "../../SubscribersIndex/main";
import SubscribersStore "../../SubscribersStore/main";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public func init(state: State.MainState): async* () {
    let ic = actor("aaaaa-aa"):Types.InternetComputerActor;

    for (canisterId in Map.keys(state.canisters)) {
      await ic.stop_canister({ canister_id = canisterId });
      await ic.delete_canister({ canister_id = canisterId });

      Map.delete(state.canisters, phash, canisterId);
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    Cycles.add(Const.CANISTER_CREATE_COST + Const.CANISTER_TOP_UP_AMOUNT);

    let publishersIndex = await PublishersIndex.PublishersIndex();

    let publishersIndexId = Principal.fromActor(publishersIndex);

    Map.set(state.canisters, phash, publishersIndexId, {
      canisterId = publishersIndexId;
      canisterType = #PublishersIndex;
      var heapSize = 0;
      var balance = Const.CANISTER_TOP_UP_AMOUNT;
    });

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    Cycles.add(Const.CANISTER_CREATE_COST + Const.CANISTER_TOP_UP_AMOUNT);

    let subscribersIndex = await SubscribersIndex.SubscribersIndex();

    let subscribersIndexId = Principal.fromActor(subscribersIndex);

    Map.set(state.canisters, phash, subscribersIndexId, {
      canisterId = subscribersIndexId;
      canisterType = #SubscribersIndex;
      var heapSize = 0;
      var balance = Const.CANISTER_TOP_UP_AMOUNT;
    });

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    Cycles.add(Const.CANISTER_CREATE_COST + Const.CANISTER_TOP_UP_AMOUNT);

    let publishersStore = await PublishersStore.PublishersStore(?publishersIndexId);

    let publishersStoreId = Principal.fromActor(publishersStore);

    Map.set(state.canisters, phash, publishersStoreId, {
      canisterId = publishersStoreId;
      canisterType = #PublishersStore;
      var heapSize = 0;
      var balance = Const.CANISTER_TOP_UP_AMOUNT;
    });

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    Cycles.add(Const.CANISTER_CREATE_COST + Const.CANISTER_TOP_UP_AMOUNT);

    let subscribersStore = await SubscribersStore.SubscribersStore(?subscribersIndexId);

    let subscribersStoreId = Principal.fromActor(subscribersStore);

    Map.set(state.canisters, phash, subscribersStoreId, {
      canisterId = subscribersStoreId;
      canisterType = #SubscribersStore;
      var heapSize = 0;
      var balance = Const.CANISTER_TOP_UP_AMOUNT;
    });

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    let broadcastIds = Array.init<Principal>(4, Principal.fromBlob(""));

    for (i in Iter.range(0, 3)) {
      Cycles.add(Const.CANISTER_CREATE_COST + Const.CANISTER_TOP_UP_AMOUNT);

      let broadcast = await Broadcast.Broadcast(?publishersIndexId, ?subscribersIndexId, [subscribersStoreId]);

      let broadcastId = Principal.fromActor(broadcast);

      broadcastIds[i] := broadcastId;

      Map.set(state.canisters, phash, broadcastId, {
        canisterId = broadcastId;
        canisterType = #Broadcast;
        var heapSize = 0;
        var balance = Const.CANISTER_TOP_UP_AMOUNT;
      });
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    await publishersIndex.setPublishersStoreId(?publishersStoreId);

    await subscribersIndex.setSubscribersStoreId(?subscribersStoreId);

    await publishersIndex.addBroadcastIds(Array.freeze(broadcastIds));

    await subscribersIndex.addBroadcastIds(Array.freeze(broadcastIds));

    await publishersStore.addBroadcastIds(Array.freeze(broadcastIds));

    await subscribersStore.addBroadcastIds(Array.freeze(broadcastIds));

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    state.initialized := true;
  };
};
