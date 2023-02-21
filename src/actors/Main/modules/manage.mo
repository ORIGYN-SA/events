import Broadcast "../../Broadcast/main";
import Config "./config";
import Const "../../../common/const";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Map "mo:map/Map";
import Principal "mo:base/Principal";
import PublishersIndex "../../PublishersIndex/main";
import PublishersStore "../../PublishersStore/main";
import SubscribersIndex "../../SubscribersIndex/main";
import SubscribersStore "../../SubscribersStore/main";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public func checkBroadcastSpace(state: State.MainState, canister: State.Canister): async* () {
    if (canister.heapSize > Const.CANISTER_DEACTIVATE_THRESHOLD) {
      let spareBroadcast = Map.find<Principal, State.Canister>(state.canisters, func(key, item) {
        return not item.active and item.canisterType == #Broadcast and item.heapSize < Const.CANISTER_REACTIVATE_THRESHOLD;
      });

      switch (spareBroadcast) {
        case (?(key, spareBroadcast)) {
          let broadcast = actor(Principal.toText(spareBroadcast.canisterId)):Broadcast.Broadcast;

          state.broadcastVersion += 1;

          await broadcast.setActiveStatus(true, state.broadcastVersion);

          canister.active := false;
          spareBroadcast.active := true;
        };

        case (_) {
          let subscribersStoreIds = Map.toArrayMap<Principal, State.Canister, Principal>(state.canisters, func(id, canister) {
            return if (canister.canisterType == #SubscribersStore) ?id else null;
          });

          state.broadcastVersion += 1;

          Cycles.add(Const.CANISTER_CREATE_COST + Const.CANISTER_TOP_UP_AMOUNT);

          let broadcast = await Broadcast.Broadcast(?state.publishersIndexId, ?state.subscribersIndexId, ?subscribersStoreIds, ?state.broadcastVersion);

          let broadcastId = Principal.fromActor(broadcast);

          canister.active := false;

          Map.set(state.canisters, phash, broadcastId, {
            canisterId = broadcastId;
            canisterType = #Broadcast;
            var status = #Running:State.CanisterStatus;
            var active = true;
            var heapSize = 0;
            var balance = Const.CANISTER_TOP_UP_AMOUNT;
          });
        };
      };
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func checkPublishersStoreSpace(state: State.MainState, canister: State.Canister): async* () {
    if (canister.heapSize > Const.CANISTER_DEACTIVATE_THRESHOLD) {
      let publishersIndex = actor(Principal.toText(state.publishersIndexId)):PublishersIndex.PublishersIndex;

      let sparePublishersStore = Map.find<Principal, State.Canister>(state.canisters, func(key, item) {
        return not item.active and item.canisterType == #PublishersStore and item.heapSize < Const.CANISTER_REACTIVATE_THRESHOLD;
      });

      switch (sparePublishersStore) {
        case (?(key, sparePublishersStore)) {
          await publishersIndex.setPublishersStoreId(?sparePublishersStore.canisterId);

          canister.active := false;
          sparePublishersStore.active := true;
        };

        case (_) {
          let broadcastIds = Map.toArrayMap<Principal, State.Canister, Principal>(state.canisters, func(id, canister) = ?id);

          Cycles.add(Const.CANISTER_CREATE_COST + Const.CANISTER_TOP_UP_AMOUNT);

          let publishersStore = await PublishersStore.PublishersStore(?state.publishersIndexId, ?broadcastIds);

          let publishersStoreId = Principal.fromActor(publishersStore);

          canister.active := false;

          Map.set(state.canisters, phash, publishersStoreId, {
            canisterId = publishersStoreId;
            canisterType = #PublishersStore;
            var status = #Running:State.CanisterStatus;
            var active = true;
            var heapSize = 0;
            var balance = Const.CANISTER_TOP_UP_AMOUNT;
          });

          await publishersIndex.setPublishersStoreId(?publishersStoreId);
        };
      };
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func checkSubscribersStoreSpace(state: State.MainState, canister: State.Canister): async* () {
    if (canister.heapSize > Const.CANISTER_DEACTIVATE_THRESHOLD) {
      let subscribersIndex = actor(Principal.toText(state.subscribersIndexId)):SubscribersIndex.SubscribersIndex;

      let spareSubscribersStore = Map.find<Principal, State.Canister>(state.canisters, func(key, item) {
        return not item.active and item.canisterType == #SubscribersStore and item.heapSize < Const.CANISTER_REACTIVATE_THRESHOLD;
      });

      switch (spareSubscribersStore) {
        case (?(key, spareSubscribersStore)) {
          await subscribersIndex.setSubscribersStoreId(?spareSubscribersStore.canisterId);

          canister.active := false;
          spareSubscribersStore.active := true;
        };

        case (_) {
          let broadcastIds = Map.toArrayMap<Principal, State.Canister, Principal>(state.canisters, func(id, canister) = ?id);

          Cycles.add(Const.CANISTER_CREATE_COST + Const.CANISTER_TOP_UP_AMOUNT);

          let subscribersStore = await SubscribersStore.SubscribersStore(?state.subscribersIndexId, ?broadcastIds);

          let subscribersStoreId = Principal.fromActor(subscribersStore);

          canister.active := false;

          Map.set(state.canisters, phash, subscribersStoreId, {
            canisterId = subscribersStoreId;
            canisterType = #SubscribersStore;
            var status = #Running:State.CanisterStatus;
            var active = true;
            var heapSize = 0;
            var balance = Const.CANISTER_TOP_UP_AMOUNT;
          });

          await subscribersIndex.setSubscribersStoreId(?subscribersStoreId);
        };
      };
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func updateCanisterMetrics(state: State.MainState): async* () {
    for (canister in Map.vals(state.canisters)) try {
      let canisterActor = actor(Principal.toText(canister.canisterId)):Broadcast.Broadcast;

      let metrics = await canisterActor.getCanisterMetrics();

      canister.heapSize := metrics.heapSize;
      canister.balance := metrics.balance;
    } catch (err) {
      Debug.print(Error.message(err));
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func checkCanisterCycles(state: State.MainState): async* () {
    let ic = actor("aaaaa-aa"):Types.InternetComputerActor;

    for (canister in Map.vals(state.canisters)) try {
      if (canister.balance < Const.CANISTER_TOP_UP_THRESHOLD) {
        Cycles.add(Const.CANISTER_TOP_UP_AMOUNT);

        await ic.deposit_cycles({ canister_id = canister.canisterId });

        canister.balance += Const.CANISTER_TOP_UP_AMOUNT;
      };
    } catch (err) {
      Debug.print(Error.message(err));
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func manageCanisters(state: State.MainState): async* () {
    if (state.status == #Running) {
      await* updateCanisterMetrics(state);

      await* checkCanisterCycles(state);

      for (canister in Map.vals(state.canisters)) try {
        if (canister.active and canister.canisterType == #Broadcast) await* checkBroadcastSpace(state, canister);

        if (canister.active and canister.canisterType == #PublishersStore) await* checkPublishersStoreSpace(state, canister);

        if (canister.active and canister.canisterType == #SubscribersStore) await* checkSubscribersStoreSpace(state, canister);
      } catch (err) {
        Debug.print(Error.message(err));
      };
    };
  };
};
