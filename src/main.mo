import Admin "./modules/admin";
import Broadcast "./modules/broadcast";
import Candy "mo:candy/types";
import Debug "mo:base/Debug";
import MigrationTypes "./migrations/types";
import Migrations "./migrations";
import Prim "mo:prim";
import Publish "./modules/publish";
import Stats "./modules/stats";
import Subscribe "./modules/subscribe";

shared (deployer) actor class EventSystem() {
  let { time } = Prim;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  stable var migrationState: MigrationTypes.State = #v0_0_0(#data);

  migrationState := Migrations.migrate(migrationState, #v0_3_0(#id), {});

  let state = switch (migrationState) { case (#v0_3_0(#data(state))) state; case (_) Debug.trap("Unexpected migration state") };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  let PublishModule = Publish.init(state, deployer.caller);

  let SubscribeModule = Subscribe.init(state, deployer.caller);

  let StatsModule = Stats.init(state, deployer.caller);

  let BroadcastModule = Broadcast.init(state, deployer.caller);

  let AdminModule = Admin.init(state, deployer.caller);

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func registerPublication(eventName: Text, options: Publish.PublicationOptions): async () {
    ignore PublishModule.registerPublication(context.caller, eventName, options);
  };

  public shared (context) func removePublication(eventName: Text, options: Publish.RemovePublicationOptions): async () {
    PublishModule.removePublication(context.caller, eventName, options);
  };

  public shared (context) func publish(eventName: Text, payload: Candy.CandyValue): async () {
    PublishModule.publish(context.caller, eventName, payload);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func registerSubscriber(caller: Principal, options: Subscribe.SubscriberOptions): async () {
    ignore SubscribeModule.registerSubscriber(context.caller, options);
  };

  public shared (context) func subscribe(eventName: Text, options: Subscribe.SubscriptionOptions): async () {
    ignore SubscribeModule.subscribe(context.caller, eventName, options);
  };

  public shared (context) func unsubscribe(eventName: Text, options: Subscribe.UnsubscribeOptions): async () {
    SubscribeModule.unsubscribe(context.caller, eventName, options);
  };

  public shared (context) func requestMissedEvents(eventName: Text, options: Subscribe.MissedEventOptions): async () {
    SubscribeModule.requestMissedEvents(context.caller, eventName, options);
  };

  public shared (context) func confirmListener(subscriberId: Principal, allow: Bool) {
    SubscribeModule.confirmListener(context.caller, subscriberId, allow);
  };

  public shared (context) func confirmEventProcessed(eventId: Nat): async () {
    SubscribeModule.confirmEventProcessed(context.caller, eventId);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func getPublicationStats(options: Stats.StatsOptions): async Stats.Stats {
    StatsModule.getPublicationStats(context.caller, options);
  };

  public shared (context) func getSubscriptionStats(options: Stats.StatsOptions): async Stats.Stats {
    StatsModule.getSubscriptionStats(context.caller, options);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func fetchSubscribers(params: Admin.FetchSubscribersParams): async Admin.FetchSubscribersResponse {
    AdminModule.fetchSubscribers(context.caller, params);
  };

  public query (context) func fetchEvents(params: Admin.FetchEventsParams): async Admin.FetchEventsResponse {
    AdminModule.fetchEvents(context.caller, params);
  };

  public query (context) func getAdmins(): async [Principal] {
    AdminModule.getAdmins(context.caller);
  };

  public shared (context) func addAdmin(principalId: Principal): async () {
    AdminModule.addAdmin(context.caller, principalId);
  };

  public shared (context) func removeAdmin(principalId: Principal): async () {
    AdminModule.removeAdmin(context.caller, principalId);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func whoami(): async Principal {
    return context.caller;
  };

  public query func getTime(): async Nat64 {
    return time();
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  system func heartbeat(): async () {
    await BroadcastModule.broadcast();
  };
};
