import Array "mo:base/Array";
import Broadcast "../../Broadcast/main";
import Config "./config";
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
      var status = #Running:State.CanisterStatus;
      var active = true;
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
      var status = #Running:State.CanisterStatus;
      var active = true;
      var heapSize = 0;
      var balance = Const.CANISTER_TOP_UP_AMOUNT;
    });

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    Cycles.add(Const.CANISTER_CREATE_COST + Const.CANISTER_TOP_UP_AMOUNT);

    let publishersStore = await PublishersStore.PublishersStore(?publishersIndexId, null);

    let publishersStoreId = Principal.fromActor(publishersStore);

    Map.set(state.canisters, phash, publishersStoreId, {
      canisterId = publishersStoreId;
      canisterType = #PublishersStore;
      var status = #Running:State.CanisterStatus;
      var active = true;
      var heapSize = 0;
      var balance = Const.CANISTER_TOP_UP_AMOUNT;
    });

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    Cycles.add(Const.CANISTER_CREATE_COST + Const.CANISTER_TOP_UP_AMOUNT);

    let subscribersStore = await SubscribersStore.SubscribersStore(?subscribersIndexId, null);

    let subscribersStoreId = Principal.fromActor(subscribersStore);

    Map.set(state.canisters, phash, subscribersStoreId, {
      canisterId = subscribersStoreId;
      canisterType = #SubscribersStore;
      var status = #Running:State.CanisterStatus;
      var active = true;
      var heapSize = 0;
      var balance = Const.CANISTER_TOP_UP_AMOUNT;
    });

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    for (i in Iter.range(0, 3)) {
      Cycles.add(Const.CANISTER_CREATE_COST + Const.CANISTER_TOP_UP_AMOUNT);

      let broadcast = await Broadcast.Broadcast(?publishersIndexId, ?subscribersIndexId, ?[subscribersStoreId], ?state.broadcastVersion);

      let broadcastId = Principal.fromActor(broadcast);

      state.broadcastVersion += 1;

      Map.set(state.canisters, phash, broadcastId, {
        canisterId = broadcastId;
        canisterType = #Broadcast;
        var status = #Running:State.CanisterStatus;
        var active = true;
        var heapSize = 0;
        var balance = Const.CANISTER_TOP_UP_AMOUNT;
      });
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    let broadcastIds = Map.toArrayMap<Principal, State.Canister, Principal>(state.canisters, func(id, canister) = ?id);

    await publishersIndex.setPublishersStoreId(?publishersStoreId);

    await subscribersIndex.setSubscribersStoreId(?subscribersStoreId);

    await publishersIndex.addBroadcastIds(broadcastIds);

    await subscribersIndex.addBroadcastIds(broadcastIds);

    await publishersStore.addBroadcastIds(broadcastIds);

    await subscribersStore.addBroadcastIds(broadcastIds);

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    state.initialized := true;
  };
};
