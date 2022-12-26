import Const "../../../common/const";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Info "./info";
import Map "mo:map/Map";
import Set "mo:map/Set";
import Stats "../../../common/stats";
import { get = coalesce } "mo:base/Option";
import { time } "mo:prim";
import { unwrap } "../../../utils/misc";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
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

  public func init(state: State.PublishersStoreState, deployer: Principal): {
    registerPublication: (caller: Principal, publisherId: Principal, eventName: Text, options: ?PublicationOptions) -> PublicationResponse;
    removePublication: (caller: Principal, publisherId: Principal, eventName: Text, options: ?RemovePublicationOptions) -> RemovePublicationResponse;
  } = object {
    let { publishers; publications } = state;

    let InfoModule = Info.init(state, deployer);

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func registerPublication(caller: Principal, publisherId: Principal, eventName: Text, options: ?PublicationOptions): PublicationResponse {
      if (caller != deployer) Debug.trap(Errors.PERMISSION_DENIED);

      let prevPublicationInfo = InfoModule.getPublicationInfo(caller, publisherId, eventName, options);

      let publisher = Map.update<Principal, State.Publisher>(publishers, phash, publisherId, func(key, value) = coalesce(value, {
        id = publisherId;
        createdAt = time();
        var activePublications = 0:Nat8;
        publications = Set.new(thash);
      }));

      Set.add(publisher.publications, thash, eventName);

      if (Set.size(publisher.publications) > Const.PUBLICATIONS_LIMIT) Debug.trap(Errors.PUBLICATIONS_LENGTH);

      let publicationGroup = Map.update<Text, State.PublicationGroup>(publications, thash, eventName, func(key, value) {
        return coalesce<State.PublicationGroup>(value, Map.new(phash));
      });

      let publication = Map.update<Principal, State.Publication>(publicationGroup, phash, publisherId, func(key, value) = coalesce(value, {
        eventName = eventName;
        publisherId = publisherId;
        createdAt = time();
        stats = Stats.build();
        var active = false;
        whitelist = Set.new(phash);
      }));

      if (not publication.active) {
        publication.active := true;
        publisher.activePublications += 1;

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

      let publicationInfo = unwrap(InfoModule.getPublicationInfo(caller, publisherId, eventName, options));

      return { publication; publicationInfo; prevPublicationInfo };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func removePublication(caller: Principal, publisherId: Principal, eventName: Text, options: ?RemovePublicationOptions): RemovePublicationResponse {
      if (caller != deployer) Debug.trap(Errors.PERMISSION_DENIED);

      if (eventName.size() > Const.EVENT_NAME_LENGTH_LIMIT) Debug.trap(Errors.EVENT_NAME_LENGTH);

      let prevPublicationInfo = InfoModule.getPublicationInfo(caller, publisherId, eventName, options);

      ignore do ?{
        let publisher = Map.get(publishers, phash, publisherId)!;
        let publicationGroup = Map.get(publications, thash, eventName)!;
        let publication = Map.get(publicationGroup, phash, publisherId)!;

        if (publication.active) {
          publication.active := false;
          publisher.activePublications -= 1;
        };

        if (options!.purge!) {
          Set.delete(publisher.publications, thash, eventName);
          Map.delete(publicationGroup, phash, publisherId);

          if (Map.size(publicationGroup) == 0) Map.delete(publications, thash, eventName);
        };
      };

      let publicationInfo = InfoModule.getPublicationInfo(caller, publisherId, eventName, options);

      return { publicationInfo; prevPublicationInfo };
    };
  };
};
