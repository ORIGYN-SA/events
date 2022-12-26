import Candy "mo:candy/types";
import Confirm "./modules/confirm";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Errors "../../common/errors";
import Info "./modules/info";
import Migrations "../../migrations";
import MigrationTypes "../../migrations/types";
import Publish "./modules/publish";
import Request "./modules/request";
import Stats "./modules/stats";
import { defaultArgs } "../../migrations";

let Types = MigrationTypes.Types;

shared (deployer) actor class Broadcast(canisters: [Types.SharedCanister]) {
  stable var migrationState: MigrationTypes.StateList = #v0_0_0(#data(#Broadcast));

  migrationState := Migrations.migrate(migrationState, #v0_1_0(#id), { defaultArgs with canisters });

  let state = switch (migrationState) { case (#v0_1_0(#data(#Broadcast(state)))) state; case (_) Debug.trap(Errors.CURRENT_MIGRATION_STATE) };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  let ConfirmModule = Confirm.init(state, deployer.caller);

  let InfoModule = Info.init(state, deployer.caller);

  let PublishModule = Publish.init(state, deployer.caller);

  let RequestModule = Request.init(state, deployer.caller);

  let StatsModule = Stats.init(state, deployer.caller);

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func confirmEventProcessed(eventId: Nat): async Confirm.ConfirmEventResponse {
    ConfirmModule.confirmEventProcessed(context.caller, eventId);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func getEventInfo(publisherId: Principal, eventId: Nat): async ?Types.SharedEvent {
    InfoModule.getEventInfo(context.caller, publisherId, eventId);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func publish(eventName: Text, payload: Candy.CandyValue): async Publish.PublishResponse {
    PublishModule.publish(context.caller, eventName, payload);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func requestEvents(missedOnly: Bool, requests: [Request.EventsRequest]): async () {
    RequestModule.requestEvents(context.caller, missedOnly, requests);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query func addCycles(): async () {
    ignore Cycles.accept(Cycles.available());
  };
};
