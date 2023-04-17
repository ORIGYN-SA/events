import Config "./modules/config";
import Debug "mo:base/Debug";
import Errors "../../common/errors";
import Info "./modules/info";
import MigrationTypes "../../migrations/types";
import Migrations "../../migrations";
import Register "./modules/register";
import Stats "./modules/stats";
import Supply "./modules/supply";
import { defaultArgs } "../../migrations";

shared (deployer) actor class PublishersStore(
  publishersIndexId: ?Principal,
  broadcastIds: ?[Principal],
) {
  stable var migrationState: MigrationTypes.StateList = #v0_0_0(#data(#PublishersStore));

  migrationState := Migrations.migrate(migrationState, #v0_1_0(#id), {
    defaultArgs with
    mainId = ?deployer.caller;
    publishersIndexId = publishersIndexId;
    broadcastIds = broadcastIds;
  });

  let state = switch (migrationState) { case (#v0_1_0(#data(#PublishersStore(state)))) state; case (_) Debug.trap(Errors.CURRENT_MIGRATION_STATE) };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func addBroadcastIds(params: Config.BroadcastIdsParams): async Config.BroadcastIdsResponse {
    return Config.addBroadcastIds(context.caller, state, params);
  };

  public query (context) func getCanisterMetrics(params: Config.CanisterMetricsParams): async Config.CanisterMetricsResponse {
    return Config.getCanisterMetrics(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func getPublisherInfo(params: Info.PublisherInfoParams): async Info.PublisherInfoResponse {
    return Info.getPublisherInfo(context.caller, state, params);
  };

  public query (context) func getPublicationInfo(params: Info.PublicationInfoParams): async Info.PublicationInfoResponse {
    return Info.getPublicationInfo(context.caller, state, params);
  };

  public query (context) func getPublicationStats(params: Info.PublicationStatsParams): async Info.PublicationStatsResponse {
    return Info.getPublicationStats(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func registerPublisher(params: Register.PublisherParams): async Register.PublisherResponse {
    return Register.registerPublisher(context.caller, state, params);
  };

  public shared (context) func registerPublication(params: Register.PublicationParams): async Register.PublicationResponse {
    return Register.registerPublication(context.caller, state, params);
  };

  public shared (context) func removePublication(params: Register.RemovePublicationParams): async Register.RemovePublicationResponse {
    return Register.removePublication(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func mergePublicationStats(params: Stats.MergeStatsParams): async Stats.MergeStatsResponse {
    return Stats.mergePublicationStats(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func supplyPublicationData(params: Supply.PublicationDataParams): async Supply.PublicationDataResponse {
    return Supply.supplyPublicationData(context.caller, state, params);
  };
};
