import Candy "mo:candy/types";
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

let Types = MigrationTypes.Types;

shared (deployer) actor class SubscribersStore(canisters: [Types.SharedCanister]) {
  stable var migrationState: MigrationTypes.StateList = #v0_0_0(#data(#SubscribersStore));

  migrationState := Migrations.migrate(migrationState, #v0_1_0(#id), { defaultArgs with canisters });

  let state = switch (migrationState) { case (#v0_1_0(#data(#SubscribersStore(state)))) state; case (_) Debug.trap(Errors.CURRENT_MIGRATION_STATE) };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  let InfoModule = Info.init(state, deployer.caller);

  let ListenModule = Listen.init(state, deployer.caller);

  let StatsModule = Stats.init(state, deployer.caller);

  let SubscribeModule = Subscribe.init(state, deployer.caller);

  let SupplyModule = Supply.init(state, deployer.caller);

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func getSubscriberInfo(subscriberId: Principal, options: ?Info.SubscriberInfoOptions): async ?Types.SharedSubscriber {
    InfoModule.getSubscriberInfo(context.caller, subscriberId, options);
  };

  public query (context) func getSubscriptionInfo(subscriberId: Principal, eventName: Text): async ?Types.SharedSubscription {
    InfoModule.getSubscriptionInfo(context.caller, subscriberId, eventName);
  };

  public query (context) func getSubscriptionStats(subscriberId: Principal, options: ?Info.SubscriptionStatsOptions): async Types.SharedStats {
    InfoModule.getSubscriptionStats(context.caller, subscriberId, options);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func removeListener(listenerId: Principal, subscriberId: Principal): async Listen.RemoveListenerResponse {
    ListenModule.removeListener(context.caller, listenerId, subscriberId);
  };

  public shared (context) func confirmListener(listenerId: Principal, subscriberId: Principal): async Listen.ConfirmListenerResponse {
    ListenModule.confirmListener(context.caller, listenerId, subscriberId);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func consumeSubscriptionStats(TransferStats: [Stats.TransferStats]): async [Stats.ConsumedStats] {
    StatsModule.consumeSubscriptionStats(context.caller, TransferStats);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func registerSubscriber(subscriberId: Principal, options: ?Subscribe.SubscriberOptions): async Subscribe.SubscriberInfo {
    SubscribeModule.registerSubscriber(context.caller, subscriberId, options);
  };

  public shared (context) func subscribe(subscriberId: Principal, eventName: Text, options: ?Subscribe.SubscriptionOptions): async Subscribe.SubscriptionInfo {
    SubscribeModule.subscribe(context.caller, subscriberId, eventName, options);
  };

  public shared (context) func unsubscribe(subscriberId: Principal, eventName: Text, options: ?Subscribe.UnsubscribeOptions): async Subscribe.UnsubscribeResponse {
    SubscribeModule.unsubscribe(context.caller, subscriberId, eventName, options);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func supplySubscribersBatch(eventName: Text, payload: Candy.CandyValue, options: Supply.SubscribersBatchOptions): async [(Principal, Principal)] {
    SupplyModule.supplySubscribersBatch(context.caller, eventName, payload, options);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query func addCycles(): async Nat {
    return Cycles.accept(Cycles.available());
  };
};
