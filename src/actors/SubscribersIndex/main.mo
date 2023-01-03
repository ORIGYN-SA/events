import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Errors "../../common/errors";
import Location "./modules/location";
import MigrationTypes "../../migrations/types";
import Migrations "../../migrations";
import Subscribe "./modules/subscribe";
import Transfer "./modules/transfer";
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

  public query (context) func getSubscriberLocation(params: Location.GetLocationParams): async Location.GetLocationResponse {
    Location.getSubscriberLocation(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func registerSubscriber(params: Subscribe.SubscriberParams): async Subscribe.SubscriberResponse {
    return await* Subscribe.registerSubscriber(context.caller, state, params);
  };

  public shared (context) func subscribe(params: Subscribe.SubscriptionParams): async Subscribe.SubscriptionResponse {
    return await* Subscribe.subscribe(context.caller, state, params);
  };

  public shared (context) func unsubscribe(params: Subscribe.UnsubscribeParams): async Subscribe.UnsubscribeResponse {
    return await* Subscribe.unsubscribe(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func transferSubscriptionStats(params: Transfer.TransferStatsParams): async Transfer.TransferStatsResponse {
    return await* Transfer.transferSubscriptionStats(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query func addCycles(): async Nat {
    return Cycles.accept(Cycles.available());
  };
};