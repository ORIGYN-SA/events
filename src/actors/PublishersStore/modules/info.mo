import Const "../../../common/const";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Set "mo:map/Set";
import Stats "../../../common/stats";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type PublisherInfoOptions = {
    includePublications: ?Bool;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type PublicationInfoOptions = {
    includeWhitelist: ?Bool;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type PublicationStatsOptions = {
    active: ?Bool;
    eventNames: ?[Text];
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.PublishersStoreState, deployer: Principal): {
    getPublisherInfo: (caller: Principal, publisherId: Principal, options: ?PublisherInfoOptions) -> ?Types.SharedPublisher;
    getPublicationInfo: (caller: Principal, publisherId: Principal, eventName: Text, options: ?PublicationInfoOptions) -> ?Types.SharedPublication;
    getPublicationStats: (caller: Principal, publisherId: Principal, options: ?PublicationStatsOptions) -> Types.SharedStats;
  } = object {
    let { publishers; publications } = state;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func getPublisherInfo(caller: Principal, publisherId: Principal, options: ?PublisherInfoOptions): ?Types.SharedPublisher {
      if (caller != deployer) Debug.trap(Errors.PERMISSION_DENIED);

      var result = null:?Types.SharedPublisher;

      ignore do ?{
        let publisher = Map.get(publishers, phash, publisherId)!;

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

    public func getPublicationInfo(caller: Principal, publisherId: Principal, eventName: Text, options: ?PublicationInfoOptions): ?Types.SharedPublication {
      if (caller != deployer) Debug.trap(Errors.PERMISSION_DENIED);

      var result = null:?Types.SharedPublication;

      ignore do ?{
        let publicationGroup = Map.get(publications, thash, eventName)!;
        let publication = Map.get(publicationGroup, phash, publisherId)!;

        var whitelist = []:[Principal];

        ignore do ?{ if (options!.includeWhitelist!) whitelist := Set.toArray(publication.whitelist) };

        result := ?{
          eventName = publication.eventName;
          publisherId = publication.publisherId;
          createdAt = publication.createdAt;
          stats = Stats.share(publication.stats);
          active = publication.active;
          whitelist = whitelist;
        };
      };

      return result;
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func getPublicationStats(caller: Principal, publisherId: Principal, options: ?PublicationStatsOptions): Types.SharedStats {
      if (caller != deployer) Debug.trap(Errors.PERMISSION_DENIED);

      let stats = Stats.build();

      ignore do ?{
        let publisher = Map.get(publishers, phash, publisherId)!;

        var eventNamesIter = Set.keys(publisher.publications):Set.IterNext<Text>;

        ignore do ?{
          if (options!.eventNames!.size() > Const.PUBLICATIONS_LIMIT) Debug.trap(Errors.EVENT_NAME_LENGTH);

          eventNamesIter := options!.eventNames!.vals();
        };

        for (eventName in eventNamesIter) label iteration ignore do ?{
          let publicationGroup = Map.get(publications, thash, eventName)!;
          let publication = Map.get(publicationGroup, phash, publisherId)!;

          ignore do ? { if (publication.active != options!.active!) break iteration };

          stats.numberOfEvents += publication.stats.numberOfEvents;
          stats.numberOfNotifications += publication.stats.numberOfNotifications;
          stats.numberOfResendNotifications += publication.stats.numberOfResendNotifications;
          stats.numberOfRequestedNotifications += publication.stats.numberOfRequestedNotifications;
          stats.numberOfConfirmations += publication.stats.numberOfConfirmations;
        };
      };

      return Stats.share(stats);
    };
  };
};
