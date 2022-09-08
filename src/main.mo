import Admin "./modules/admin";
import Candy "mo:candy/types";
import Debug "mo:base/Debug";
import MigrationTypes "./migrations/types";
import Migrations "./migrations";
import Prim "mo:prim";
import Publish "./modules/publish";
import Subscribe "./modules/subscribe";

shared (deployer) actor class EventSystem() {
  let { time } = Prim;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  stable var migrationState: MigrationTypes.State = #v0_0_0(#data);

  migrationState := Migrations.migrate(migrationState, #v0_1_0(#id), {});

  let state = switch (migrationState) { case (#v0_1_0(#data(state))) state; case (_) Debug.trap("Unexpected migration state") };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  let PublishModule = Publish.init(state, deployer.caller);

  let SubscribeModule = Subscribe.init(state, deployer.caller);

  let AdminModule = Admin.init(state, deployer.caller);

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func registerPublication(eventName: Text, options: Publish.PublicationOptions): async () {
    PublishModule.registerPublication(context.caller, eventName, options);
  };

  public shared (context) func removePublication(eventName: Text, options: Publish.RemovePublicationOptions): async () {
    PublishModule.removePublication(context.caller, eventName, options);
  };

  public shared (context) func publish(eventName: Text, payload: Candy.CandyValue): async () {
    await PublishModule.publish(context.caller, eventName, payload);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func subscribe(eventName: Text, options: Subscribe.SubscriptionOptions): async () {
    SubscribeModule.subscribe(context.caller, eventName, options);
  };

  public shared (context) func unsubscribe(eventName: Text, options: Subscribe.UnsubscribeOptions): async () {
    SubscribeModule.unsubscribe(context.caller, eventName, options);
  };

  public shared (context) func requestMissedEvents(eventName: Text, options: Subscribe.MissedEventOptions): async () {
    await SubscribeModule.requestMissedEvents(context.caller, eventName, options);
  };

  public shared (context) func confirmEventProcessed(eventId: Nat): async () {
    SubscribeModule.confirmEventProcessed(context.caller, eventId);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func fetchSubscribers(params: Admin.FetchSubscribersParams): async Admin.FetchSubscribersResponse {
    AdminModule.fetchSubscribers(context.caller, params);
  };

  public query (context) func fetchEvents(params: Admin.FetchEventsParams): async Admin.FetchEventsResponse {
    AdminModule.fetchEvents(context.caller, params);
  };

  public shared (context) func removeSubscribers(subscriberIds: [Principal]): async () {
    AdminModule.removeSubscribers(context.caller, subscriberIds);
  };

  public shared (context) func removeEvents(eventIds: [Nat]): async () {
    AdminModule.removeEvents(context.caller, eventIds);
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
    await PublishModule.broadcast();
  };
};
