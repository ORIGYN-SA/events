import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Errors "../../common/errors";
import Index "./modules/index";
import MigrationTypes "../../migrations/types";
import Migrations "../../migrations";
import { defaultArgs } "../../migrations";

let Types = MigrationTypes.Types;

shared actor class SubscribersIndex(
  mainId: ?Principal,
  subscribersStoreIds: [Principal],
  broadcastIds: [Principal],
) {
  stable var migrationState: MigrationTypes.StateList = #v0_0_0(#data(#SubscribersIndex));

  migrationState := Migrations.migrate(migrationState, #v0_1_0(#id), { defaultArgs with mainId; subscribersStoreIds; broadcastIds });

  let state = switch (migrationState) { case (#v0_1_0(#data(#SubscribersIndex(state)))) state; case (_) Debug.trap(Errors.CURRENT_MIGRATION_STATE) };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func getSubscriberLocation(params: Index.GetLocationParams): async Index.GetLocationResponse {
    Index.getSubscriberLocation(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query func addCycles(): async Nat {
    return Cycles.accept(Cycles.available());
  };
};
