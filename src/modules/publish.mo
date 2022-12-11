import Candy "mo:candy/types";
import CandyUtils "mo:candy_utils/CandyUtils";
import Const "./const";
import Debug "mo:base/Debug";
import Errors "./errors";
import Info "./info";
import Map "mo:map/Map";
import MigrationTypes "../migrations/types";
import Option "mo:base/Option";
import Prim "mo:prim";
import Principal "mo:base/Principal";
import Set "mo:map/Set";
import Types "./types";
import Utils "../utils/misc";

module {
  let State = MigrationTypes.Current;

  let { get = coalesce } = Option;

  let { get } = CandyUtils;

  let { unwrap } = Utils;

  let { nhash; thash; phash; lhash } = Map;

  let { time } = Prim;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type PublicationOptions = {
    whitelist: ?[Principal];
    whitelistAdd: ?[Principal];
    whitelistRemove: ?[Principal];
    includeWhitelist: ?Bool;
  };

  public type PublicationInfo = {
    publicationInfo: Types.SharedPublication;
    prevPublicationInfo: ?Types.SharedPublication;
  };

  public type PublicationResponse = {
    publication: State.Publication;
    publicationInfo: Types.SharedPublication;
    prevPublicationInfo: ?Types.SharedPublication;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type RemovePublicationOptions = {
    purge: ?Bool;
    includeWhitelist: ?Bool;
  };

  public type RemovePublicationResponse = {
    publicationInfo: ?Types.SharedPublication;
    prevPublicationInfo: ?Types.SharedPublication;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type PublishResponse = {
    eventInfo: ?Types.SharedEvent;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.State, deployer: Principal): {
    registerPublication: (caller: Principal, eventName: Text, options: ?PublicationOptions) -> PublicationResponse;
    removePublication: (caller: Principal, eventName: Text, options: ?RemovePublicationOptions) -> RemovePublicationResponse;
    publish: (caller: Principal, eventName: Text, payload: Candy.CandyValue) -> PublishResponse;
  } = object {
    let { publishers; publications; subscribers; subscriptions; events } = state;

    let InfoModule = Info.init(state, deployer);

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func registerPublication(caller: Principal, eventName: Text, options: ?PublicationOptions): PublicationResponse {
      let prevPublicationInfo = InfoModule.getPublicationInfo(caller, eventName, options);

      let publisher = Map.update<Principal, State.Publisher>(publishers, phash, caller, func(key, value) = coalesce(value, {
        id = caller;
        createdAt = time();
        var activePublications = 0:Nat8;
        publications = Set.new(thash);
      }));

      Set.add(publisher.publications, thash, eventName);

      if (Set.size(publisher.publications) > Const.PUBLICATIONS_LIMIT) Debug.trap(Errors.PUBLICATIONS_LENGTH);

      let publicationGroup = Map.update<Text, State.PublicationGroup>(publications, thash, eventName, func(key, value) {
        return coalesce<State.PublicationGroup>(value, Map.new(phash));
      });

      let publication = Map.update<Principal, State.Publication>(publicationGroup, phash, caller, func(key, value) = coalesce(value, {
        eventName = eventName;
        publisherId = caller;
        createdAt = time();
        var active = false;
        var numberOfEvents = 0:Nat64;
        var numberOfNotifications = 0:Nat64;
        var numberOfResendNotifications = 0:Nat64;
        var numberOfRequestedNotifications = 0:Nat64;
        var numberOfConfirmations = 0:Nat64;
        whitelist = Set.new(phash);
      }));

      if (not publication.active) {
        publication.active := true;
        publisher.activePublications +%= 1;

        if (publisher.activePublications > Const.ACTIVE_PUBLICATIONS_LIMIT) Debug.trap(Errors.ACTIVE_PUBLICATIONS_LENGTH);
      };

      ignore do ?{
        if (options!.whitelist!.size() > Const.WHITELIST_LIMIT) Debug.trap(Errors.WHITELIST_REPLACE_LENGTH);

        Set.clear(publication.whitelist);

        for (principalId in options!.whitelist!.vals()) Set.add(publication.whitelist, phash, principalId);
      };

      ignore do ?{
        if (options!.whitelistAdd!.size() > Const.WHITELIST_LIMIT) Debug.trap(Errors.WHITELIST_ADD_LENGTH);

        for (principalId in options!.whitelistAdd!.vals()) Set.add(publication.whitelist, phash, principalId);

        if (Set.size(publication.whitelist) > Const.WHITELIST_LIMIT) Debug.trap(Errors.WHITELIST_LENGTH);
      };

      ignore do ?{
        if (options!.whitelistRemove!.size() > Const.WHITELIST_LIMIT) Debug.trap(Errors.WHITELIST_REMOVE_LENGTH);

        for (principalId in options!.whitelistRemove!.vals()) Set.delete(publication.whitelist, phash, principalId);
      };

      let publicationInfo = unwrap(InfoModule.getPublicationInfo(caller, eventName, options));

      return { publication; publicationInfo; prevPublicationInfo };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func removePublication(caller: Principal, eventName: Text, options: ?RemovePublicationOptions): RemovePublicationResponse {
      if (eventName.size() > Const.EVENT_NAME_LENGTH_LIMIT) Debug.trap(Errors.EVENT_NAME_LENGTH);

      let prevPublicationInfo = InfoModule.getPublicationInfo(caller, eventName, options);

      ignore do ?{
        let publisher = Map.get(publishers, phash, caller)!;
        let publicationGroup = Map.get(publications, thash, eventName)!;
        let publication = Map.get(publicationGroup, phash, caller)!;

        if (publication.active) {
          publication.active := false;
          publisher.activePublications -%= 1;
        };

        if (options!.purge!) {
          Set.delete(publisher.publications, thash, eventName);
          Map.delete(publicationGroup, phash, caller);

          if (Map.size(publicationGroup) == 0) Map.delete(publications, thash, eventName);
        };
      };

      let publicationInfo = InfoModule.getPublicationInfo(caller, eventName, options);

      return { publicationInfo; prevPublicationInfo };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func publish(caller: Principal, eventName: Text, payload: Candy.CandyValue): PublishResponse {
      if (eventName.size() > Const.EVENT_NAME_LENGTH_LIMIT) Debug.trap(Errors.EVENT_NAME_LENGTH);

      let eventId = state.eventId;

      let { publication } = registerPublication(caller, eventName, null);

      publication.numberOfEvents +%= 1;

      ignore do ?{
        let subscriptionGroup = Map.get(subscriptions, thash, eventName)!;
        let eventSubscribers = Map.new<Principal, Nat8>(phash);

        let subscriberIdsIter = if (Set.size(publication.whitelist) > 0) Set.keys(publication.whitelist) else Map.keys(subscriptionGroup);

        for (subscriberId in subscriberIdsIter) ignore do ?{
          let subscription = Map.get(subscriptionGroup, phash, subscriberId)!;

          if (subscription.active) {
            let filterValue = do ?{ get(payload, subscription.filterPath!) };

            if (filterValue != ?#Bool(false)) {
              if (subscription.skipped >= subscription.skip) {
                subscription.skipped := 0;

                Map.set(eventSubscribers, phash, subscriberId, 0:Nat8);
                Set.add(subscription.events, nhash, eventId);

                subscription.numberOfEvents +%= 1;
              } else {
                subscription.skipped +%= 1;
              };
            };
          };
        };

        if (Map.size(eventSubscribers) > 0) {
          Map.set(events, nhash, eventId, {
            id = eventId;
            eventName = eventName;
            publisherId = caller;
            payload = payload;
            createdAt = time();
            var nextBroadcastTime = time();
            var numberOfAttempts = 0:Nat8;
            resendRequests = Set.new(phash);
            subscribers = eventSubscribers;
          });

          state.eventId += 1;

          state.nextBroadcastTime := time();
        };
      };

      return { eventInfo = InfoModule.getEventInfo(caller, eventId) };
    };
  };
};
