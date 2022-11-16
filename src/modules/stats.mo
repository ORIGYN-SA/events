import Const "./const";
import Debug "mo:base/Debug";
import Errors "./errors";
import Map "mo:map/Map";
import MigrationTypes "../migrations/types";
import Set "mo:map/Set";

module {
  let State = MigrationTypes.Current;

  let { nhash; thash; phash; lhash } = Map;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type StatsOptions = {
    active: ?Bool;
    eventNames: ?[Text];
  };

  public type StatsResponse = {
    numberOfEvents: Nat64;
    numberOfNotifications: Nat64;
    numberOfResendNotifications: Nat64;
    numberOfRequestedNotifications: Nat64;
    numberOfConfirmations: Nat64;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.State, deployer: Principal): {
    getPublicationStats: (caller: Principal, options: ?StatsOptions) -> StatsResponse;
    getSubscriptionStats: (caller: Principal, options: ?StatsOptions) -> StatsResponse;
  } = object {
    let { publishers; publications; subscribers; subscriptions } = state;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func getPublicationStats(caller: Principal, options: ?StatsOptions): StatsResponse {
      var numberOfEvents = 0:Nat64;
      var numberOfNotifications = 0:Nat64;
      var numberOfResendNotifications = 0:Nat64;
      var numberOfRequestedNotifications = 0:Nat64;
      var numberOfConfirmations = 0:Nat64;

      ignore do ?{
        let publisher = Map.get(publishers, phash, caller)!;

        var eventNamesIter = Set.keys(publisher.publications):Set.IterNext<Text>;

        ignore do ?{
          if (options!.eventNames!.size() > Const.PUBLICATIONS_LIMIT) Debug.trap(Errors.EVENT_NAME_LENGTH);

          eventNamesIter := options!.eventNames!.vals();
        };

        for (eventName in eventNamesIter) label iteration ignore do ?{
          let publicationGroup = Map.get(publications, thash, eventName)!;
          let publication = Map.get(publicationGroup, phash, caller)!;

          ignore do ? { if (publication.active != options!.active!) break iteration };

          numberOfEvents +%= publication.numberOfEvents;
          numberOfNotifications +%= publication.numberOfNotifications;
          numberOfResendNotifications +%= publication.numberOfResendNotifications;
          numberOfRequestedNotifications +%= publication.numberOfRequestedNotifications;
          numberOfConfirmations +%= publication.numberOfConfirmations;
        };
      };

      return {
        numberOfEvents;
        numberOfNotifications;
        numberOfResendNotifications;
        numberOfRequestedNotifications;
        numberOfConfirmations;
      };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func getSubscriptionStats(caller: Principal, options: ?StatsOptions): StatsResponse {
      var numberOfEvents = 0:Nat64;
      var numberOfNotifications = 0:Nat64;
      var numberOfResendNotifications = 0:Nat64;
      var numberOfRequestedNotifications = 0:Nat64;
      var numberOfConfirmations = 0:Nat64;

      ignore do ?{
        let subscriber = Map.get(subscribers, phash, caller)!;

        var eventNamesIter = Set.keys(subscriber.subscriptions):Set.IterNext<Text>;

        ignore do ?{
          if (options!.eventNames!.size() > Const.PUBLICATIONS_LIMIT) Debug.trap(Errors.EVENT_NAME_LENGTH);

          eventNamesIter := options!.eventNames!.vals();
        };

        for (eventName in eventNamesIter) label iteration ignore do ?{
          let subscriptionGroup = Map.get(subscriptions, thash, eventName)!;
          let subscription = Map.get(subscriptionGroup, phash, caller)!;

          ignore do ? { if (subscription.active != options!.active!) break iteration };

          numberOfEvents +%= subscription.numberOfEvents;
          numberOfNotifications +%= subscription.numberOfNotifications;
          numberOfResendNotifications +%= subscription.numberOfResendNotifications;
          numberOfRequestedNotifications +%= subscription.numberOfRequestedNotifications;
          numberOfConfirmations +%= subscription.numberOfConfirmations;
        };
      };

      return {
        numberOfEvents;
        numberOfNotifications;
        numberOfResendNotifications;
        numberOfRequestedNotifications;
        numberOfConfirmations;
      };
    };
  };
};
