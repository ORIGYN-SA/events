import Config "./modules/config";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Errors "../../common/errors";
import Info "./modules/info";
import MigrationTypes "../../migrations/types";
import Migrations "../../migrations";
import Register "./modules/register";
import Stats "./modules/stats";
import Supply "./modules/supply";
import { defaultArgs } "../../migrations";

shared (deployer) actor class PublishersStore(publishersIndexId: ?Principal) {
  stable var migrationState: MigrationTypes.StateList = #v0_0_0(#data(#PublishersStore));

  migrationState := Migrations.migrate(migrationState, #v0_1_0(#id), { defaultArgs with publishersIndexId; mainId = ?deployer.caller });

  let state = switch (migrationState) { case (#v0_1_0(#data(#PublishersStore(state)))) state; case (_) Debug.trap(Errors.CURRENT_MIGRATION_STATE) };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func addBroadcastIds(params: Config.BroadcastIdsParams): async Config.BroadcastIdsResponse {
    return Config.addBroadcastIds(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func getPublisherInfo(params: Info.PublisherInfoParams): async Info.PublisherInfoResponse {
    Info.getPublisherInfo(context.caller, state, params);
  };

  public query (context) func getPublicationInfo(params: Info.PublicationInfoParams): async Info.PublicationInfoResponse {
    Info.getPublicationInfo(context.caller, state, params);
  };

  public query (context) func getPublicationStats(params: Info.PublicationStatsParams): async Info.PublicationStatsResponse {
    Info.getPublicationStats(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func registerPublisher(params: Register.PublisherParams): async Register.PublisherResponse {
    Register.registerPublisher(context.caller, state, params);
  };

  public shared (context) func registerPublication(params: Register.PublicationParams): async Register.PublicationResponse {
    Register.registerPublication(context.caller, state, params);
  };

  public shared (context) func removePublication(params: Register.RemovePublicationParams): async Register.RemovePublicationResponse {
    Register.removePublication(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func consumePublicationStats(params: Stats.ConsumeStatsParams): async Stats.ConsumeStatsResponse {
    Stats.consumePublicationStats(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func supplyPublicationData(params: Supply.PublicationDataParams): async Supply.PublicationDataResponse {
    Supply.supplyPublicationData(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query func addCycles(): async Nat {
    return Cycles.accept(Cycles.available());
  };
};
