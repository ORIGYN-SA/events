import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Errors "../../common/errors";
import Index "./modules/index";
import MigrationTypes "../../migrations/types";
import Migrations "../../migrations";
import Register "./modules/register";
import { defaultArgs } "../../migrations";

let Types = MigrationTypes.Types;

shared actor class PublishersIndex(
  mainId: ?Principal,
  publishersStoreIds: [Principal],
  broadcastIds: [Principal],
) {
  stable var migrationState: MigrationTypes.StateList = #v0_0_0(#data(#PublishersIndex));

  migrationState := Migrations.migrate(migrationState, #v0_1_0(#id), { defaultArgs with mainId; publishersStoreIds; broadcastIds });

  let state = switch (migrationState) { case (#v0_1_0(#data(#PublishersIndex(state)))) state; case (_) Debug.trap(Errors.CURRENT_MIGRATION_STATE) };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func getPublisherLocation(params: Index.GetLocationParams): async Index.GetLocationResponse {
    return Index.getPublisherLocation(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func registerPublisher(params: Register.PublisherParams): async Register.PublisherResponse {
    return await Register.registerPublisher(context.caller, state, params);
  };

  public shared (context) func registerPublication(params: Register.PublicationParams): async Register.PublicationResponse {
    return await Register.registerPublication(context.caller, state, params);
  };

  public shared (context) func removePublication(params: Register.RemovePublicationParams): async Register.RemovePublicationResponse {
    return await Register.removePublication(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query func addCycles(): async Nat {
    return Cycles.accept(Cycles.available());
  };
};
