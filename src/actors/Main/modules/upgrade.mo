import Broadcast "../../Broadcast/main";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Principal "mo:base/Principal";
import PublishersIndex "../../PublishersIndex/main";
import PublishersStore "../../PublishersStore/main";
import Set "mo:map/Set";
import SubscribersIndex "../../SubscribersIndex/main";
import SubscribersStore "../../SubscribersStore/main";
import { n32hash; n64hash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public func prepareUpgrade(state: State.MainState) {
    if (state.status == #Upgrading) Debug.trap(Errors.UPGRADE_IN_PROGRESS);

    state.status := #Upgrading;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type FinishUpgradeResponse = ();

  public type FinishUpgradeParams = ();

  public type FinishUpgradeFullParams = (caller: Principal, state: State.MainState, params: FinishUpgradeParams);

  public func finishUpgrade((caller, state, (upgradeType)): FinishUpgradeFullParams): async* () {
    if (caller != state.mainId and not Set.has(state.admins, phash, caller)) Debug.trap(Errors.PERMISSION_DENIED);

    state.status := #Upgrading;

    try await async {
      let ic = actor("aaaaa-aa"):Types.InternetComputerActor;

      for (canister in Map.vals(state.canisters)) {
        if (canister.canisterType == #Broadcast) {
          await ic.stop_canister({ canister_id = canister.canisterId });

          canister.status := #Stopped;
        };
      };

      for (canister in Map.vals(state.canisters)) {
        if (canister.canisterType == #PublishersIndex or canister.canisterType == #SubscribersIndex) {
          await ic.stop_canister({ canister_id = canister.canisterId });

          canister.status := #Stopped;
        };
      };

      for (canister in Map.vals(state.canisters)) {
        if (canister.canisterType == #PublishersStore or canister.canisterType == #SubscribersStore) {
          await ic.stop_canister({ canister_id = canister.canisterId });

          canister.status := #Stopped;
        };
      };

      for (canister in Map.vals(state.canisters)) {
        canister.status := #Upgrading;

        switch (canister.canisterType) {
          case (#Broadcast) {
            let broadcast = actor(Principal.toText(canister.canisterId)):Broadcast.Broadcast;

            ignore await (system Broadcast.Broadcast)(#upgrade(broadcast))(null, null, null, null);
          };

          case (#PublishersIndex) {
            let publishersIndex = actor(Principal.toText(canister.canisterId)):PublishersIndex.PublishersIndex;

            ignore await (system PublishersIndex.PublishersIndex)(#upgrade(publishersIndex))();
          };

          case (#PublishersStore) {
            let publishersStore = actor(Principal.toText(canister.canisterId)):PublishersStore.PublishersStore;

            ignore await (system PublishersStore.PublishersStore)(#upgrade(publishersStore))(null, null);
          };

          case (#SubscribersIndex) {
            let subscribersIndex = actor(Principal.toText(canister.canisterId)):SubscribersIndex.SubscribersIndex;

            ignore await (system SubscribersIndex.SubscribersIndex)(#upgrade(subscribersIndex))();
          };

          case (#SubscribersStore) {
            let subscribersStore = actor(Principal.toText(canister.canisterId)):SubscribersStore.SubscribersStore;

            ignore await (system SubscribersStore.SubscribersStore)(#upgrade(subscribersStore))(null, null);
          };

          case (_) {};
        };

        canister.status := #Upgraded;
      };

      for (canister in Map.vals(state.canisters)) {
        if (canister.canisterType == #PublishersStore or canister.canisterType == #SubscribersStore) {
          await ic.start_canister({ canister_id = canister.canisterId });

          canister.status := #Running;
        };
      };

      for (canister in Map.vals(state.canisters)) {
        if (canister.canisterType == #PublishersIndex or canister.canisterType == #SubscribersIndex) {
          await ic.start_canister({ canister_id = canister.canisterId });

          canister.status := #Running;
        };
      };

      for (canister in Map.vals(state.canisters)) {
        if (canister.canisterType == #Broadcast) {
          await ic.start_canister({ canister_id = canister.canisterId });

          canister.status := #Running;
        };
      };

      state.status := #Running;
    } catch (err) {
      state.status := #UpgradeFailed;

      throw err;
    };
  };
};
