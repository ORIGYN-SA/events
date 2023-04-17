import Config "./modules/config";
import Debug "mo:base/Debug";
import Errors "../../common/errors";
import Info "./modules/info";
import Location "./modules/location";
import MigrationTypes "../../migrations/types";
import Migrations "../../migrations";
import Subscribe "./modules/subscribe";
import Stats "./modules/stats";
import { defaultArgs } "../../migrations";

shared (deployer) actor class SubscribersIndex() {
  stable var migrationState: MigrationTypes.StateList = #v0_0_0(#data(#SubscribersIndex));

  migrationState := Migrations.migrate(migrationState, #v0_1_0(#id), { defaultArgs with mainId = ?deployer.caller });

  let state = switch (migrationState) { case (#v0_1_0(#data(#SubscribersIndex(state)))) state; case (_) Debug.trap(Errors.CURRENT_MIGRATION_STATE) };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func setSubscribersStoreId(params: Config.SubscribersStoreIdParams): async Config.SubscribersStoreIdResponse {
    return Config.setSubscribersStoreId(context.caller, state, params);
  };

  public shared (context) func addBroadcastIds(params: Config.BroadcastIdsParams): async Config.BroadcastIdsResponse {
    return Config.addBroadcastIds(context.caller, state, params);
  };

  public query (context) func getCanisterMetrics(params: Config.CanisterMetricsParams): async Config.CanisterMetricsResponse {
    return Config.getCanisterMetrics(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func getSubscriberInfo(params: Info.SubscriberInfoParams): async Info.SubscriberInfoResponse {
    return await* Info.getSubscriberInfo(context.caller, state, params);
  };

  public shared (context) func getSubscriptionInfo(params: Info.SubscriptionInfoParams): async Info.SubscriptionInfoResponse {
    return await* Info.getSubscriptionInfo(context.caller, state, params);
  };

  public shared (context) func getSubscriptionStats(params: Info.SubscriptionStatsParams): async Info.SubscriptionStatsResponse {
    return await* Info.getSubscriptionStats(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func getSubscriberLocation(params: Location.GetLocationParams): async Location.GetLocationResponse {
    return Location.getSubscriberLocation(context.caller, state, params);
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

  public shared (context) func mergeSubscriptionStats(params: Stats.MergeStatsParams): async Stats.MergeStatsResponse {
    return await* Stats.mergeSubscriptionStats(context.caller, state, params);
  };
};
