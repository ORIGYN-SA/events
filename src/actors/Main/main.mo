import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Errors "../../common/errors";
import Init "./modules/init";
import Map "mo:map/Map";
import MigrationTypes "../../migrations/types";
import Migrations "../../migrations";
import Principal "mo:base/Principal";
import { setTimer } "mo:prim";
import { defaultArgs } "../../migrations";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../migrations/types";

shared (deployer) actor class Main() = this {
  stable var migrationState: MigrationTypes.StateList = #v0_0_0(#data(#Main));

  migrationState := Migrations.migrate(migrationState, #v0_1_0(#id), defaultArgs);

  let state = switch (migrationState) { case (#v0_1_0(#data(#Main(state)))) state; case (_) Debug.trap(Errors.CURRENT_MIGRATION_STATE) };

  if (not state.initialized) ignore setTimer(0, false, func(): async () { await* Init.init(state) });

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func requestCycles(amount: Nat): async () {
    if (not Map.has(state.canisters, phash, context.caller)) Debug.trap(Errors.PERMISSION_DENIED);

    let canister = actor(Principal.toText(context.caller)):Types.AddCyclesActor;

    Cycles.add(amount);

    await canister.addCycles();
  };

  public query func addCycles(): async Nat {
    return Cycles.accept(Cycles.available());
  };
};
