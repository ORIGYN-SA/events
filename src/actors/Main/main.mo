import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Errors "../../common/errors";
import Init "./modules/init";
import MigrationTypes "../../migrations/types";
import Migrations "../../migrations";
import { setTimer } "mo:prim";
import { defaultArgs } "../../migrations";

let Types = MigrationTypes.Types;

shared (deployer) actor class Main() {
  stable var migrationState: MigrationTypes.StateList = #v0_0_0(#data(#Main));

  migrationState := Migrations.migrate(migrationState, #v0_1_0(#id), defaultArgs);

  let state = switch (migrationState) { case (#v0_1_0(#data(#Main(state)))) state; case (_) Debug.trap(Errors.CURRENT_MIGRATION_STATE) };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  if (not state.initialized) ignore setTimer(0, false, func(): async () { await* Init.init(state) });

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func requestCycles(amount: Nat): async () {
    Cycles.add(amount);

    // (actor(Principal.toText(context.caller))).addCycles();
  };

  public query func addCycles(): async Nat {
    return Cycles.accept(Cycles.available());
  };
};
