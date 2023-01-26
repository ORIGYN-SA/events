import Config "./modules/config";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Errors "../../common/errors";
import Init "./modules/init";
import Manage "./modules/manage";
import MigrationTypes "../../migrations/types";
import Migrations "../../migrations";
import Principal "mo:base/Principal";
import { setTimer } "mo:prim";
import { defaultArgs } "../../migrations";
import { Types; State } "../../migrations/types";

shared (deployer) actor class Main() {
  stable var migrationState: MigrationTypes.StateList = #v0_0_0(#data(#Main));

  migrationState := Migrations.migrate(migrationState, #v0_1_0(#id), defaultArgs);

  let state = switch (migrationState) { case (#v0_1_0(#data(#Main(state)))) state; case (_) Debug.trap(Errors.CURRENT_MIGRATION_STATE) };

  if (not state.initialized) ignore setTimer(0, false, func(): async () { await* Init.init(state) });

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func getBroadcastIds(params: Config.BroadcastIdsParams): async Config.BroadcastIdsResponse {
    return Config.getBroadcastIds(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func requestCycles(params: Manage.RequestCyclesParams): async Manage.RequestCyclesResponse {
    return await* Manage.requestCycles(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query func addCycles(): async Nat {
    return Cycles.accept(Cycles.available());
  };
};
