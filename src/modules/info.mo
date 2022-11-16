import Debug "mo:base/Debug";
import Map "mo:map/Map";
import MigrationTypes "../migrations/types";
import Types "./types";
import Set "mo:map/Set";

module {
  let State = MigrationTypes.Current;

  let { nhash; thash; phash; lhash } = Map;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type PublisherInfoOptions = {
    includePublications: ?Bool;
  };

  public type PublicationInfoOptions = {
    includeWhitelist: ?Bool;
  };

  public type SubscriberInfoOptions = {
    includeListeners: ?Bool;
    includeSubscriptions: ?Bool;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.State, deployer: Principal): {
    getPublisherInfo: (caller: Principal, options: ?PublisherInfoOptions) -> ?Types.SharedPublisher;
    getPublicationInfo: (caller: Principal, eventName: Text, options: ?PublicationInfoOptions) -> ?Types.SharedPublication;
    getSubscriberInfo: (caller: Principal, options: ?SubscriberInfoOptions) -> ?Types.SharedSubscriber;
    getSubscriptionInfo: (caller: Principal, eventName: Text) -> ?Types.SharedSubscription;
    getEventInfo: (caller: Principal, eventId: Nat) -> ?Types.SharedEvent;
  } = object {
    let { publishers; publications; subscribers; subscriptions; events } = state;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func getPublisherInfo(caller: Principal, options: ?PublisherInfoOptions): ?Types.SharedPublisher {
      var result = null:?Types.SharedPublisher;

      ignore do ?{
        let publisher = Map.get(publishers, phash, caller)!;

        var publications = []:[Text];

        ignore do ?{ if (options!.includePublications!) publications := Set.toArray(publisher.publications) };

        result := ?{
          id = publisher.id;
          createdAt = publisher.createdAt;
          activePublications = publisher.activePublications;
          publications = publications;
        };
      };

      return result;
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func getPublicationInfo(caller: Principal, eventName: Text, options: ?PublicationInfoOptions): ?Types.SharedPublication {
      var result = null:?Types.SharedPublication;

      ignore do ?{
        let publicationGroup = Map.get(publications, thash, eventName)!;
        let publication = Map.get(publicationGroup, phash, caller)!;

        var whitelist = []:[Principal];

        ignore do ?{ if (options!.includeWhitelist!) whitelist := Set.toArray(publication.whitelist) };

        result := ?{
          eventName = publication.eventName;
          publisherId = publication.publisherId;
          createdAt = publication.createdAt;
          active = publication.active;
          numberOfEvents = publication.numberOfEvents;
          numberOfNotifications = publication.numberOfNotifications;
          numberOfResendNotifications = publication.numberOfResendNotifications;
          numberOfRequestedNotifications = publication.numberOfRequestedNotifications;
          numberOfConfirmations = publication.numberOfConfirmations;
          whitelist = whitelist;
        };
      };

      return result;
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func getSubscriberInfo(caller: Principal, options: ?SubscriberInfoOptions): ?Types.SharedSubscriber {
      var result = null:?Types.SharedSubscriber;

      ignore do ?{
        let subscriber = Map.get(subscribers, phash, caller)!;

        var listeners = []:[Principal];
        var confirmedListeners = []:[Principal];
        var subscriptions = []:[Text];

        ignore do ?{ if (options!.includeSubscriptions!) { subscriptions := Set.toArray(subscriber.subscriptions) } };

        ignore do ?{ if (options!.includeListeners!) { listeners := Set.toArray(subscriber.listeners) } };

        ignore do ?{ if (options!.includeListeners!) { confirmedListeners := Set.toArray(subscriber.confirmedListeners) } };

        result := ?{
          id = subscriber.id;
          createdAt = subscriber.createdAt;
          activeSubscriptions = subscriber.activeSubscriptions;
          listeners = listeners;
          confirmedListeners = confirmedListeners;
          subscriptions = subscriptions;
        };
      };

      return result;
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func getSubscriptionInfo(caller: Principal, eventName: Text): ?Types.SharedSubscription {
      var result = null:?Types.SharedSubscription;

      ignore do ?{
        let subscriptionGroup = Map.get(subscriptions, thash, eventName)!;
        let subscription = Map.get(subscriptionGroup, phash, caller)!;

        result := ?{
          eventName = subscription.eventName;
          subscriberId = subscription.subscriberId;
          createdAt = subscription.createdAt;
          skip = subscription.skip;
          skipped = subscription.skipped;
          active = subscription.active;
          stopped = subscription.stopped;
          filter = subscription.filter;
          numberOfEvents = subscription.numberOfEvents;
          numberOfNotifications = subscription.numberOfNotifications;
          numberOfResendNotifications = subscription.numberOfResendNotifications;
          numberOfRequestedNotifications = subscription.numberOfRequestedNotifications;
          numberOfConfirmations = subscription.numberOfConfirmations;
        };
      };

      return result;
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func getEventInfo(caller: Principal, eventId: Nat): ?Types.SharedEvent {
      var result = null:?Types.SharedEvent;

      ignore do ?{
        let event = Map.get(events, nhash, eventId)!;

        if (event.publisherId == caller) result := ?{
          id = event.id;
          eventName = event.eventName;
          publisherId = event.publisherId;
          payload = event.payload;
          createdAt = event.createdAt;
          nextBroadcastTime = event.nextBroadcastTime;
          numberOfAttempts = event.numberOfAttempts;
        };
      };

      return result;
    };
  };
};
