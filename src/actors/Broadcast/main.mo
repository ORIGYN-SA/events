import Config "./modules/config";
import Confirm "./modules/confirm";
import Const "../../common/const";
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
import { setBlockingTimer } "../../utils/timer";

shared (deployer) actor class Broadcast(
  publishersIndexId: ?Principal,
  subscribersIndexId: ?Principal,
  subscribersStoreIds: ?[Principal],
  broadcastVersion: ?Nat64,
) {
  stable var migrationState: MigrationTypes.StateList = #v0_0_0(#data(#Broadcast));

  migrationState := Migrations.migrate(migrationState, #v0_1_0(#id), {
    defaultArgs with
    mainId = ?deployer.caller;
    publishersIndexId = publishersIndexId;
    subscribersIndexId = subscribersIndexId;
    subscribersStoreIds = subscribersStoreIds;
    broadcastVersion = broadcastVersion;
  });

  let state = switch (migrationState) { case (#v0_1_0(#data(#Broadcast(state)))) state; case (_) Debug.trap(Errors.CURRENT_MIGRATION_STATE) };

  ignore setBlockingTimer(Const.RESEND_CHECK_DELAY, func(): async* () { await* Deliver.resendCheck(state) });

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func addSubscribersStoreIds(params: Config.SubscribersStoreIdsParams): async Config.SubscribersStoreIdsResponse {
    return Config.addSubscribersStoreIds(context.caller, state, params);
  };

  public query (context) func getCanisterMetrics(params: Config.CanisterMetricsParams): async Config.CanisterMetricsResponse {
    return Config.getCanisterMetrics(context.caller, state, params);
  };

  public shared (context) func setStatus(params: Config.StatusParams): async Config.StatusResponse {
    return Config.setStatus(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func confirmEventReceipt(params: Confirm.ConfirmEventParams): async Confirm.ConfirmEventResponse {
    return Confirm.confirmEventReceipt(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func getEventInfo(params: Info.EventInfoParams): async Info.EventInfoResponse {
    return Info.getEventInfo(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func publish(params: Publish.PublishParams): async Publish.PublishResponse {
    return await* Publish.publish(context.caller, state, params);
  };

  public shared (context) func publishBatch(params: Publish.PublishBatchParams): async Publish.PublishBatchResponse {
    return await* Publish.publishBatch(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func requestEvents(params: Request.RequestEventsParams): async Request.RequestEventsResponse {
    return Request.requestEvents(context.caller, state, params);
  };
};
