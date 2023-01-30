import Broadcast "../../Broadcast/main";
import Const "../../../common/const";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Principal "mo:base/Principal";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public func updateCanisterMetrics(state: State.MainState): async* () {
    let ic = actor("aaaaa-aa"):Types.InternetComputerActor;

    for (canister in Map.vals(state.canisters)) try {
      let canisterActor = actor(Principal.toText(canister.canisterId)):Broadcast.Broadcast;

      let metrics = await canisterActor.getCanisterMetrics();

      canister.heapSize := metrics.heapSize;
      canister.balance := metrics.balance;

      if (canister.balance < Const.CANISTER_TOP_UP_THRESHOLD) {
        Cycles.add(Const.CANISTER_TOP_UP_AMOUNT);

        await ic.deposit_cycles({ canister_id = canister.canisterId });

        canister.balance += Const.CANISTER_TOP_UP_AMOUNT;
      };
    } catch (err) {
      Debug.print(Error.message(err));
    };
  };
};
