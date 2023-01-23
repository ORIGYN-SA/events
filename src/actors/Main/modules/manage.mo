import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Principal "mo:base/Principal";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type RequestCyclesResponse = ();

  public type RequestCyclesParams = (amount: Nat);

  public type RequestCyclesFullParams = (caller: Principal, state: State.MainState, params: RequestCyclesParams);

  public func requestCycles((caller, state, (amount)): RequestCyclesFullParams): async* RequestCyclesResponse {
    if (not Map.has(state.canisters, phash, caller)) Debug.trap(Errors.PERMISSION_DENIED);

    let canister = actor(Principal.toText(caller)):Types.AddCyclesActor;

    Cycles.add(amount);

    await canister.addCycles();
  };
};
