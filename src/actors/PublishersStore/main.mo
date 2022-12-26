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

let Types = MigrationTypes.Types;

shared (deployer) actor class PublishersStore(canisters: [Types.SharedCanister]) {
  stable var migrationState: MigrationTypes.StateList = #v0_0_0(#data(#PublishersStore));

  migrationState := Migrations.migrate(migrationState, #v0_1_0(#id), { defaultArgs with canisters });

  let state = switch (migrationState) { case (#v0_1_0(#data(#PublishersStore(state)))) state; case (_) Debug.trap(Errors.CURRENT_MIGRATION_STATE) };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  let InfoModule = Info.init(state, deployer.caller);

  let RegisterModule = Register.init(state, deployer.caller);

  let StatsModule = Stats.init(state, deployer.caller);

  let SupplyModule = Supply.init(state, deployer.caller);

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func getPublisherInfo(publisherId: Principal, options: ?Info.PublisherInfoOptions): async ?Types.SharedPublisher {
    InfoModule.getPublisherInfo(context.caller, publisherId, options);
  };

  public query (context) func getPublicationInfo(publisherId: Principal, eventName: Text, options: ?Info.PublicationInfoOptions): async ?Types.SharedPublication {
    InfoModule.getPublicationInfo(context.caller, publisherId, eventName, options);
  };

  public query (context) func getPublicationStats(publisherId: Principal, options: ?Info.PublicationStatsOptions): async Types.SharedStats {
    InfoModule.getPublicationStats(context.caller, publisherId, options);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func registerPublication(publisherId: Principal, eventName: Text, options: ?Register.PublicationOptions): async Register.PublicationInfo {
    RegisterModule.registerPublication(context.caller, publisherId, eventName, options);
  };

  public shared (context) func removePublication(publisherId: Principal, eventName: Text, options: ?Register.RemovePublicationOptions): async Register.RemovePublicationResponse {
    RegisterModule.removePublication(context.caller, publisherId, eventName, options);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func consumePublicationStats(TransferStats: [Stats.TransferStats]): async [Stats.ConsumedStats] {
    StatsModule.consumePublicationStats(context.caller, TransferStats);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func supplyPublicationData(publisherId: Principal, eventName: Text): async Supply.PublicationDataResponse {
    SupplyModule.supplyPublicationData(context.caller, publisherId, eventName);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query func addCycles(): async Nat {
    return Cycles.accept(Cycles.available());
  };
};
