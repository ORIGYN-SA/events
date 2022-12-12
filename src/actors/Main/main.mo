import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Errors "../../common/errors";
import MigrationTypes "../../migrations/types";
import Migrations "../../migrations";

shared (deployer) actor class Main() {
  stable var migrationState: MigrationTypes.State = #v0_0_0(#data(#Main));

  migrationState := Migrations.migrate(migrationState, #v0_1_0(#id), {});

  let state = switch (migrationState) { case (#v0_1_0(#data(#Main(state)))) state; case (_) Debug.trap(Errors.CURRENT_MIGRATION_STATE) };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func requestCycles(amount: Nat): async () {
    Cycles.add(amount);

    (actor(Principal.toText(context.caller))).addCycles();
  };

  public query func addCycles(): async () {
    ignore Cycles.accept(Cycles.available());
  };
};
