import Const "../../../common/const";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Set "mo:map/Set";
import Stats "../../../common/stats";
import { n32hash; n64hash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type PublisherInfoOptions = {
    includePublications: ?Bool;
  };

  public type PublisherInfoResponse = ?Types.SharedPublisher;

  public type PublisherInfoParams = (publisherId: Principal, options: ?PublisherInfoOptions);

  public type PublisherInfoFullParams = (caller: Principal, state: State.PublishersStoreState, params: PublisherInfoParams);

  public func getPublisherInfo((caller, state, (publisherId, options)): PublisherInfoFullParams): PublisherInfoResponse {
    if (caller != state.publishersIndexId) Debug.trap(Errors.PERMISSION_DENIED);

    let ?publisher = Map.get(state.publishers, phash, publisherId) else return null;

    var publications = []:[Text];

    ignore do ?{
      if (options!.includePublications!) publications := Set.toArray(publisher.publications);
    };

    return ?{
      id = publisher.id;
      createdAt = publisher.createdAt;
      activePublications = publisher.activePublications;
      publications = publications;
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type PublicationInfoOptions = {
    includeSubscriberWhitelist: ?Bool;
  };

  public type PublicationInfoResponse = ?Types.SharedPublication;

  public type PublicationInfoParams = (publisherId: Principal, eventName: Text, options: ?PublicationInfoOptions);

  public type PublicationInfoFullParams = (caller: Principal, state: State.PublishersStoreState, params: PublicationInfoParams);

  public func getPublicationInfo((caller, state, (publisherId, eventName, options)): PublicationInfoFullParams): PublicationInfoResponse {
    if (caller != state.publishersIndexId) Debug.trap(Errors.PERMISSION_DENIED);

    let ?publicationGroup = Map.get(state.publications, thash, eventName) else return null;
    let ?publication = Map.get(publicationGroup, phash, publisherId) else return null;

    var subscriberWhitelist = []:[Principal];

    ignore do ?{
      if (options!.includeSubscriberWhitelist!) subscriberWhitelist := Set.toArray(publication.subscriberWhitelist);
    };

    return ?{
      eventName = publication.eventName;
      publisherId = publication.publisherId;
      createdAt = publication.createdAt;
      stats = Stats.share(publication.stats);
      active = publication.active;
      subscriberWhitelist = subscriberWhitelist;
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type PublicationStatsOptions = {
    active: ?Bool;
    eventNames: ?[Text];
  };

  public type PublicationStatsResponse = Types.SharedStats;

  public type PublicationStatsParams = (publisherId: Principal, options: ?PublicationStatsOptions);

  public type PublicationStatsFullParams = (caller: Principal, state: State.PublishersStoreState, params: PublicationStatsParams);

  public func getPublicationStats((caller, state, (publisherId, options)): PublicationStatsFullParams): PublicationStatsResponse {
    if (caller != state.publishersIndexId) Debug.trap(Errors.PERMISSION_DENIED);

    let ?publisher = Map.get(state.publishers, phash, publisherId) else return Stats.empty;

    var eventNamesIter = Set.keys(publisher.publications):Set.IterNext<Text>;

    let stats = Stats.build();

    ignore do ?{
      if (options!.eventNames!.size() > Const.SUBSCRIPTIONS_LIMIT) Debug.trap(Errors.SUBSCRIPTIONS_OPTION_LENGTH);

      eventNamesIter := options!.eventNames!.vals();
    };

    for (eventName in eventNamesIter) label iteration {
      let ?publicationGroup = Map.get(state.publications, thash, eventName) else break iteration;
      let ?publication = Map.get(publicationGroup, phash, publisherId) else break iteration;

      ignore do ? {
        if (publication.active != options!.active!) break iteration;
      };

      stats.numberOfEvents += publication.stats.numberOfEvents;
      stats.numberOfNotifications += publication.stats.numberOfNotifications;
      stats.numberOfResendNotifications += publication.stats.numberOfResendNotifications;
      stats.numberOfRequestedNotifications += publication.stats.numberOfRequestedNotifications;
      stats.numberOfConfirmations += publication.stats.numberOfConfirmations;
    };

    return Stats.share(stats);
  };
};
