import Config "./modules/config";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Errors "../../common/errors";
import Info "./modules/info";
import Listen "./modules/listen";
import MigrationTypes "../../migrations/types";
import Migrations "../../migrations";
import Stats "./modules/stats";
import Subscribe "./modules/subscribe";
import Supply "./modules/supply";
import { defaultArgs } "../../migrations";

shared (deployer) actor class SubscribersStore(subscribersIndexId: ?Principal) {
  stable var migrationState: MigrationTypes.StateList = #v0_0_0(#data(#SubscribersStore));

  migrationState := Migrations.migrate(migrationState, #v0_1_0(#id), { defaultArgs with subscribersIndexId; mainId = ?deployer.caller });

  let state = switch (migrationState) { case (#v0_1_0(#data(#SubscribersStore(state)))) state; case (_) Debug.trap(Errors.CURRENT_MIGRATION_STATE) };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func addBroadcastIds(params: Config.BroadcastIdsParams): async Config.BroadcastIdsResponse {
    return Config.addBroadcastIds(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func getSubscriberInfo(params: Info.SubscriberInfoParams): async Info.SubscriberInfoResponse {
    Info.getSubscriberInfo(context.caller, state, params);
  };

  public query (context) func getSubscriptionInfo(params: Info.SubscriptionInfoParams): async Info.SubscriptionInfoResponse {
    Info.getSubscriptionInfo(context.caller, state, params);
  };

  public query (context) func getSubscriptionStats(params: Info.SubscriptionStatsParams): async Info.SubscriptionStatsResponse {
    Info.getSubscriptionStats(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func confirmListener(params: Listen.ConfirmListenerParams): async Listen.ConfirmListenerResponse {
    Listen.confirmListener(context.caller, state, params);
  };

  public shared (context) func removeListener(params: Listen.RemoveListenerParams): async Listen.RemoveListenerResponse {
    Listen.removeListener(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func consumeSubscriptionStats(params: Stats.ConsumeStatsParams): async Stats.ConsumeStatsResponse {
    Stats.consumeSubscriptionStats(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func registerSubscriber(params: Subscribe.SubscriberParams): async Subscribe.SubscriberResponse {
    Subscribe.registerSubscriber(context.caller, state, params);
  };

  public shared (context) func subscribe(params: Subscribe.SubscriptionParams): async Subscribe.SubscriptionResponse {
    Subscribe.subscribe(context.caller, state, params);
  };

  public shared (context) func unsubscribe(params: Subscribe.UnsubscribeParams): async Subscribe.UnsubscribeResponse {
    Subscribe.unsubscribe(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func supplySubscribersBatch(params: Supply.SubscribersBatchParams): async Supply.SubscribersBatchResponse {
    Supply.supplySubscribersBatch(context.caller, state, params);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query func addCycles(): async Nat {
    return Cycles.accept(Cycles.available());
  };
};
