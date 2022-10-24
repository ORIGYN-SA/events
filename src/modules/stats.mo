import Const "./const";
import Debug "mo:base/Debug";
import Map "mo:map/Map";
import MigrationTypes "../migrations/types";
import Option "mo:base/Option";
import Set "mo:map/Set";

module {
  let State = MigrationTypes.Current;

  let { isNull } = Option;

  let { nhash; thash; phash; lhash } = Map;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  let StatsOptionsSize = 2;

  public type StatsOptions = [{
    #active: Bool;
    #eventNames: [Text];
  }];

  public type Stats = {
    numberOfEvents: Nat64;
    numberOfNotifications: Nat64;
    numberOfResendNotifications: Nat64;
    numberOfRequestedNotifications: Nat64;
    numberOfConfirmations: Nat64;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.State, deployer: Principal): {
    getPublicationStats: (caller: Principal, options: StatsOptions) -> Stats;
    getSubscriptionStats: (caller: Principal, options: StatsOptions) -> Stats;
  } = object {
    let { publishers; publications; subscribers; subscriptions } = state;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func getPublicationStats(caller: Principal, options: StatsOptions): Stats {
      if (options.size() > StatsOptionsSize) Debug.trap("Invalid number of options");

      var numberOfEvents = 0:Nat64;
      var numberOfNotifications = 0:Nat64;
      var numberOfResendNotifications = 0:Nat64;
      var numberOfRequestedNotifications = 0:Nat64;
      var numberOfConfirmations = 0:Nat64;

      ignore do ?{
        let publisher = Map.get(publishers, phash, caller)!;
        var eventNamesIter = Set.keys(publisher.publications);
        var activeFilter = null:?Bool;

        for (option in options.vals()) switch (option) {
          case (#active(active)) activeFilter := ?active;

          case (#eventNames(eventNames)) {
            if (eventNames.size() > Const.PUBLICATIONS_LIMIT) Debug.trap("EventNames option length limit reached");

            eventNamesIter := eventNames.vals();
          };
        };

        for (eventName in eventNamesIter) ignore do ?{
          let publicationGroup = Map.get(publications, thash, eventName)!;
          let publication = Map.get(publicationGroup, phash, caller)!;

          if (isNull(activeFilter) or publication.active == activeFilter!) {
            numberOfEvents +%= publication.numberOfEvents;
            numberOfNotifications +%= publication.numberOfNotifications;
            numberOfResendNotifications +%= publication.numberOfResendNotifications;
            numberOfRequestedNotifications +%= publication.numberOfRequestedNotifications;
            numberOfConfirmations +%= publication.numberOfConfirmations;
          };
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

    public func getSubscriptionStats(caller: Principal, options: StatsOptions): Stats {
      if (options.size() > StatsOptionsSize) Debug.trap("Invalid number of options");

      var numberOfEvents = 0:Nat64;
      var numberOfNotifications = 0:Nat64;
      var numberOfResendNotifications = 0:Nat64;
      var numberOfRequestedNotifications = 0:Nat64;
      var numberOfConfirmations = 0:Nat64;

      ignore do ?{
        let subscriber = Map.get(subscribers, phash, caller)!;
        var eventNamesIter = Set.keys(subscriber.subscriptions);
        var activeFilter = null:?Bool;

        for (option in options.vals()) switch (option) {
          case (#active(active)) activeFilter := ?active;

          case (#eventNames(eventNames)) {
            if (eventNames.size() > Const.SUBSCRIPTIONS_LIMIT) Debug.trap("EventNames option length limit reached");

            eventNamesIter := eventNames.vals();
          };
        };

        for (eventName in eventNamesIter) ignore do ?{
          let subscriptionGroup = Map.get(subscriptions, thash, eventName)!;
          let subscription = Map.get(subscriptionGroup, phash, caller)!;

          if (isNull(activeFilter) or subscription.active == activeFilter!) {
            numberOfEvents +%= subscription.numberOfEvents;
            numberOfNotifications +%= subscription.numberOfNotifications;
            numberOfResendNotifications +%= subscription.numberOfResendNotifications;
            numberOfRequestedNotifications +%= subscription.numberOfRequestedNotifications;
            numberOfConfirmations +%= subscription.numberOfConfirmations;
          };
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
