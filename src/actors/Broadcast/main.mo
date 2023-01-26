import Config "./modules/config";
import Confirm "./modules/confirm";
import Const "../../common/const";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Deliver "./modules/deliver";
import Errors "../../common/errors";
import Info "./modules/info";
import Migrations "../../migrations";
import MigrationTypes "../../migrations/types";
import Publish "./modules/publish";
import Request "./modules/request";
import { setTimer } "mo:prim";
import { defaultArgs } "../../migrations";

shared (deployer) actor class Broadcast(publishersIndexId: ?Principal, subscribersIndexId: ?Principal, subscribersStoreIds: [Principal]) {
  stable var migrationState: MigrationTypes.StateList = #v0_0_0(#data(#Broadcast));

  let args = { defaultArgs with publishersIndexId; subscribersIndexId; subscribersStoreIds; mainId = ?deployer.caller }:MigrationTypes.Args;

  migrationState := Migrations.migrate(migrationState, #v0_1_0(#id), args);

  let state = switch (migrationState) { case (#v0_1_0(#data(#Broadcast(state)))) state; case (_) Debug.trap(Errors.CURRENT_MIGRATION_STATE) };

  ignore setTimer(Const.RESEND_CHECK_DELAY, true, func(): async () { Deliver.resendCheck(state) });

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func addSubscribersStoreIds(params: Config.SubscribersStoreIdsParams): async Config.SubscribersStoreIdsResponse {
    return Config.addSubscribersStoreIds(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func confirmEventProcessed(params: Confirm.ConfirmEventParams): async Confirm.ConfirmEventResponse {
    return Confirm.confirmEventProcessed(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func getEventInfo(params: Info.EventInfoParams): async Info.EventInfoResponse {
    return Info.getEventInfo(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func publish(params: Publish.PublishParams): async Publish.PublishResponse {
    return Publish.publish(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func requestEvents(params: Request.RequestEventsParams): async Request.RequestEventsResponse {
    return Request.requestEvents(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query func addCycles(): async Nat {
    return Cycles.accept(Cycles.available());
  };
};
