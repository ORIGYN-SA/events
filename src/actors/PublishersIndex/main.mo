import Config "./modules/config";
import Debug "mo:base/Debug";
import Errors "../../common/errors";
import Info "./modules/info";
import Location "./modules/location";
import MigrationTypes "../../migrations/types";
import Migrations "../../migrations";
import Register "./modules/register";
import Transfer "./modules/transfer";
import { defaultArgs } "../../migrations";

shared (deployer) actor class PublishersIndex() {
  stable var migrationState: MigrationTypes.StateList = #v0_0_0(#data(#PublishersIndex));

  migrationState := Migrations.migrate(migrationState, #v0_1_0(#id), { defaultArgs with mainId = ?deployer.caller });

  let state = switch (migrationState) { case (#v0_1_0(#data(#PublishersIndex(state)))) state; case (_) Debug.trap(Errors.CURRENT_MIGRATION_STATE) };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func setPublishersStoreId(params: Config.PublishersStoreIdParams): async Config.PublishersStoreIdResponse {
    return Config.setPublishersStoreId(context.caller, state, params);
  };

  public shared (context) func addBroadcastIds(params: Config.BroadcastIdsParams): async Config.BroadcastIdsResponse {
    return Config.addBroadcastIds(context.caller, state, params);
  };

  public query (context) func getCanisterMetrics(params: Config.CanisterMetricsParams): async Config.CanisterMetricsResponse {
    return Config.getCanisterMetrics(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func getPublisherInfo(params: Info.PublisherInfoParams): async Info.PublisherInfoResponse {
    return await* Info.getPublisherInfo(context.caller, state, params);
  };

  public shared (context) func getPublicationInfo(params: Info.PublicationInfoParams): async Info.PublicationInfoResponse {
    return await* Info.getPublicationInfo(context.caller, state, params);
  };

  public shared (context) func getPublicationStats(params: Info.PublicationStatsParams): async Info.PublicationStatsResponse {
    return await* Info.getPublicationStats(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func getPublisherLocation(params: Location.GetLocationParams): async Location.GetLocationResponse {
    return Location.getPublisherLocation(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func registerPublisher(params: Register.PublisherParams): async Register.PublisherResponse {
    return await* Register.registerPublisher(context.caller, state, params);
  };

  public shared (context) func registerPublication(params: Register.PublicationParams): async Register.PublicationResponse {
    return await* Register.registerPublication(context.caller, state, params);
  };

  public shared (context) func removePublication(params: Register.RemovePublicationParams): async Register.RemovePublicationResponse {
    return await* Register.removePublication(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func transferPublicationStats(params: Transfer.TransferStatsParams): async Transfer.TransferStatsResponse {
    return await* Transfer.transferPublicationStats(context.caller, state, params);
  };
};
