import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Errors "../../common/errors";
import Inform "./modules/inform";
import MigrationTypes "../../migrations/types";
import Migrations "../../migrations";
import Register "./modules/register";
import Supply "./modules/supply";
import Types "../../common/types";

shared (deployer) actor class PublishersStore() {
  stable var migrationState: MigrationTypes.State = #v0_0_0(#data(#PublishersStore));

  migrationState := Migrations.migrate(migrationState, #v0_1_0(#id), {});

  let state = switch (migrationState) { case (#v0_1_0(#data(#PublishersStore(state)))) state; case (_) Debug.trap(Errors.CURRENT_MIGRATION_STATE) };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  let RegisterModule = Register.init(state, deployer.caller);

  let InformModule = Inform.init(state, deployer.caller);

  let SupplyModule = Supply.init(state, deployer.caller);

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func registerPublication(publisherId: Principal, eventName: Text, options: ?Register.PublicationOptions): async Register.PublicationInfo {
    RegisterModule.registerPublication(context.caller, publisherId, eventName, options);
  };

  public shared (context) func removePublication(publisherId: Principal, eventName: Text, options: ?Register.RemovePublicationOptions): async Register.RemovePublicationResponse {
    RegisterModule.removePublication(context.caller, publisherId, eventName, options);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func getPublisherInfo(publisherId: Principal, options: ?Inform.PublisherInfoOptions): async ?Types.SharedPublisher {
    InformModule.getPublisherInfo(context.caller, publisherId, options);
  };

  public query (context) func getPublicationInfo(publisherId: Principal, eventName: Text, options: ?Inform.PublicationInfoOptions): async ?Types.SharedPublication {
    InformModule.getPublicationInfo(context.caller, publisherId, eventName, options);
  };

  public query (context) func getPublicationStats(publisherId: Principal, options: ?Inform.PublicationStatsOptions): async Types.SharedStats {
    InformModule.getPublicationStats(context.caller, publisherId, options);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func supplyPublicationData(publisherId: Principal, eventName: Text): async Supply.PublicationDataResponse {
    SupplyModule.supplyPublicationData(context.caller, publisherId, eventName);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query func addCycles(): async () {
    ignore Cycles.accept(Cycles.available());
  };
};
