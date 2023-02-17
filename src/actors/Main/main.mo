import Admin "./modules/admin";
import Config "./modules/config";
import Const "../../common/const";
import Debug "mo:base/Debug";
import Errors "../../common/errors";
import Info "./modules/info";
import Init "./modules/init";
import Manage "./modules/manage";
import MigrationTypes "../../migrations/types";
import Migrations "../../migrations";
import Principal "mo:base/Principal";
import Upgrade "./modules/upgrade";
import { setTimer } "mo:prim";
import { defaultArgs } "../../migrations";
import { setBlockingTimer } "../../utils/timer";
import { Types; State } "../../migrations/types";

shared (deployer) actor class Main() {
  stable var migrationState: MigrationTypes.StateList = #v0_0_0(#data(#Main));

  migrationState := Migrations.migrate(migrationState, #v0_1_0(#id), { defaultArgs with deployer = ?deployer.caller });

  let state = switch (migrationState) { case (#v0_1_0(#data(#Main(state)))) state; case (_) Debug.trap(Errors.CURRENT_MIGRATION_STATE) };

  if (not state.initialized) ignore setTimer(0, false, func(): async () { await* Init.init(state) });

  ignore setBlockingTimer(Const.UPDATE_METRICS_INTERVAL, func(): async* () { await* Manage.manageCanisters(state) });

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func getAdmins(params: Admin.GetAdminsParams): async Admin.GetAdminsResponse {
    return Admin.getAdmins(context.caller, state, params);
  };

  public query (context) func addAdmin(params: Admin.AddAdminParams): async Admin.AddAdminResponse {
    return Admin.addAdmin(context.caller, state, params);
  };

  public query (context) func removeAdmin(params: Admin.RemoveAdminParams): async Admin.RemoveAdminResponse {
    return Admin.removeAdmin(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func getBroadcastIds(params: Config.BroadcastIdsParams): async Config.BroadcastIdsResponse {
    return Config.getBroadcastIds(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func getUpgradeStatus(params: Info.UpgradeStatusParams): async Info.UpgradeStatusResponse {
    return Info.getUpgradeStatus(context.caller, state, params);
  };  

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func finishUpgrade(params: Upgrade.FinishUpgradeParams): async Upgrade.FinishUpgradeResponse {
    return await* Upgrade.finishUpgrade(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  system func preupgrade() {
    Upgrade.prepareUpgrade(state);
  };

  system func postupgrade() {
    ignore setTimer(0, false, func(): async () { await* Upgrade.finishUpgrade(state.mainId, state, ()); });
  };
};
