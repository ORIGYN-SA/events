import Admin "./modules/admin";
import Broadcast "./modules/broadcast";
import Candy "mo:candy/types";
import Debug "mo:base/Debug";
import Errors "./modules/errors";
import Info "./modules/info";
import Listen "./modules/listen";
import MigrationTypes "./migrations/types";
import Migrations "./migrations";
import Prim "mo:prim";
import Publish "./modules/publish";
import Stats "./modules/stats";
import Subscribe "./modules/subscribe";
import Types "./modules/types";

shared (deployer) actor class EventSystem() {
  let { time } = Prim;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  stable var migrationState: MigrationTypes.State = #v0_0_0(#data);

  migrationState := Migrations.migrate(migrationState, #v0_4_0(#id), {});

  let state = switch (migrationState) { case (#v0_4_0(#data(state))) state; case (_) Debug.trap(Errors.CURRENT_MIGRATION_STATE) };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  let PublishModule = Publish.init(state, deployer.caller);

  let SubscribeModule = Subscribe.init(state, deployer.caller);

  let ListenModule = Listen.init(state, deployer.caller);

  let StatsModule = Stats.init(state, deployer.caller);

  let InfoModule = Info.init(state, deployer.caller);

  let BroadcastModule = Broadcast.init(state, deployer.caller);

  let AdminModule = Admin.init(state, deployer.caller);

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func registerPublication(eventName: Text, options: ?Publish.PublicationOptions): async Publish.PublicationInfo {
    PublishModule.registerPublication(context.caller, eventName, options);
  };

  public shared (context) func removePublication(eventName: Text, options: ?Publish.RemovePublicationOptions): async Publish.RemovePublicationResponse {
    PublishModule.removePublication(context.caller, eventName, options);
  };

  public shared (context) func publish(eventName: Text, payload: Candy.CandyValue): async Publish.PublishResponse {
    PublishModule.publish(context.caller, eventName, payload);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func registerSubscriber(options: ?Subscribe.SubscriberOptions): async Subscribe.SubscriberInfo {
    SubscribeModule.registerSubscriber(context.caller, options);
  };

  public shared (context) func subscribe(eventName: Text, options: ?Subscribe.SubscriptionOptions): async Subscribe.SubscriptionInfo {
    SubscribeModule.subscribe(context.caller, eventName, options);
  };

  public shared (context) func unsubscribe(eventName: Text, options: ?Subscribe.UnsubscribeOptions): async Subscribe.UnsubscribeResponse {
    SubscribeModule.unsubscribe(context.caller, eventName, options);
  };

  public shared (context) func requestMissedEvents(eventName: Text, options: ?Subscribe.MissedEventsOptions): async Subscribe.MissedEventsResponse {
    SubscribeModule.requestMissedEvents(context.caller, eventName, options);
  };

  public shared (context) func confirmEventProcessed(eventId: Nat): async Subscribe.ConfirmEventResponse {
    SubscribeModule.confirmEventProcessed(context.caller, eventId);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public shared (context) func removeListener(): async Listen.RemoveListenerResponse {
    ListenModule.removeListener(context.caller);
  };

  public shared (context) func confirmListener(subscriberIdParam: Principal): async Listen.ConfirmListenerResponse {
    ListenModule.confirmListener(context.caller, subscriberIdParam);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func getPublicationStats(options: ?Stats.StatsOptions): async Stats.StatsResponse {
    StatsModule.getPublicationStats(context.caller, options);
  };

  public query (context) func getSubscriptionStats(options: ?Stats.StatsOptions): async Stats.StatsResponse {
    StatsModule.getSubscriptionStats(context.caller, options);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func getPublisherInfo(options: ?Info.PublisherInfoOptions): async ?Types.SharedPublisher {
    InfoModule.getPublisherInfo(context.caller, options);
  };

  public query (context) func getPublicationInfo(eventName: Text, options: ?Info.PublicationInfoOptions): async ?Types.SharedPublication {
    InfoModule.getPublicationInfo(context.caller, eventName, options);
  };

  public query (context) func getSubscriberInfo(options: ?Info.SubscriberInfoOptions): async ?Types.SharedSubscriber {
    InfoModule.getSubscriberInfo(context.caller, options);
  };

  public query (context) func getSubscriptionInfo(eventName: Text): async ?Types.SharedSubscription {
    InfoModule.getSubscriptionInfo(context.caller, eventName);
  };

  public query (context) func getEventInfo(eventId: Nat): async ?Types.SharedEvent {
    InfoModule.getEventInfo(context.caller, eventId);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (context) func fetchSubscribers(params: Admin.FetchSubscribersOptions): async Admin.FetchSubscribersResponse {
    AdminModule.fetchSubscribers(context.caller, params);
  };

  public query (context) func fetchEvents(params: Admin.FetchEventsOptions): async Admin.FetchEventsResponse {
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
