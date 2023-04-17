import Const "../../../common/const";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Info "./info";
import Map "mo:map/Map";
import Set "mo:map/Set";
import Stats "../../../common/stats";
import { time } "mo:prim";
import { n32hash; n64hash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type PublisherOptions = {
    includePublications: ?Bool;
  };

  public type PublisherResponse = {
    publisherInfo: Types.SharedPublisher;
    prevPublisherInfo: ?Types.SharedPublisher;
  };

  public type PublisherFullResponse = {
    publisher: State.Publisher;
    publisherInfo: Types.SharedPublisher;
    prevPublisherInfo: ?Types.SharedPublisher;
  };

  public type PublisherParams = (publisherId: Principal, options: ?PublisherOptions);

  public type PublisherFullParams = (caller: Principal, state: State.PublishersStoreState, params: PublisherParams);

  public func registerPublisher((caller, state, (publisherId, options)): PublisherFullParams): PublisherFullResponse {
    if (caller != state.publishersIndexId) Debug.trap(Errors.PERMISSION_DENIED);

    let prevPublisherInfo = Info.getPublisherInfo(state.publishersIndexId, state, (publisherId, options));

    let ?publisher = Map.update<Principal, State.Publisher>(state.publishers, phash, publisherId, func(key, value) = switch (value) {
      case (?value) ?value;

      case (_) ?{
        id = publisherId;
        createdAt = time();
        var activePublications = 0:Nat8;
        publications = Set.new(thash);
      };
    });

    let ?publisherInfo = Info.getPublisherInfo(state.publishersIndexId, state, (publisherId, options));

    return { publisher; publisherInfo; prevPublisherInfo };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type PublicationOptions = {
    subscriberWhitelist: ?[Principal];
    subscriberWhitelistAdd: ?[Principal];
    subscriberWhitelistRemove: ?[Principal];
    includeSubscriberWhitelist: ?Bool;
  };

  public type PublicationResponse = {
    publicationInfo: Types.SharedPublication;
    prevPublicationInfo: ?Types.SharedPublication;
  };

  public type PublicationFullResponse = {
    publication: State.Publication;
    publicationInfo: Types.SharedPublication;
    prevPublicationInfo: ?Types.SharedPublication;
  };

  public type PublicationParams = (publisherId: Principal, eventName: Text, options: ?PublicationOptions);

  public type PublicationFullParams = (caller: Principal, state: State.PublishersStoreState, params: PublicationParams);

  public func registerPublication((caller, state, (publisherId, eventName, options)): PublicationFullParams): PublicationFullResponse {
    if (caller != state.publishersIndexId) Debug.trap(Errors.PERMISSION_DENIED);

    let prevPublicationInfo = Info.getPublicationInfo(state.publishersIndexId, state, (publisherId, eventName, options));

    let { publisher } = registerPublisher(state.publishersIndexId, state, (publisherId, null));

    Set.add(publisher.publications, thash, eventName);

    if (Set.size(publisher.publications) > Const.PUBLICATIONS_LIMIT) Debug.trap(Errors.PUBLICATIONS_LENGTH);

    let ?publicationGroup = Map.update<Text, State.PublicationGroup>(state.publications, thash, eventName, func(key, value) {
      return switch (value) { case (?value) ?value; case (_) ?Map.new(phash) };
    });

    let ?publication = Map.update<Principal, State.Publication>(publicationGroup, phash, publisherId, func(key, value) = switch (value) {
      case (?value) ?value;

      case (_) ?{
        eventName = eventName;
        publisherId = publisherId;
        createdAt = time();
        stats = Stats.build();
        var active = false;
        subscriberWhitelist = Set.new(phash);
      };
    });

    if (not publication.active) {
      publication.active := true;
      publisher.activePublications += 1;

      if (publisher.activePublications > Const.ACTIVE_PUBLICATIONS_LIMIT) Debug.trap(Errors.ACTIVE_PUBLICATIONS_LENGTH);
    };

    ignore do ?{
      if (options!.subscriberWhitelist!.size() > Const.SUBSCRIBER_WHITELIST_LIMIT) Debug.trap(Errors.SUBSCRIBER_WHITELIST_REPLACE_LENGTH);

      Set.clear(publication.subscriberWhitelist);

      for (principalId in options!.subscriberWhitelist!.vals()) Set.add(publication.subscriberWhitelist, phash, principalId);
    };

    ignore do ?{
      if (options!.subscriberWhitelistAdd!.size() > Const.SUBSCRIBER_WHITELIST_LIMIT) Debug.trap(Errors.SUBSCRIBER_WHITELIST_ADD_LENGTH);

      for (principalId in options!.subscriberWhitelistAdd!.vals()) Set.add(publication.subscriberWhitelist, phash, principalId);

      if (Set.size(publication.subscriberWhitelist) > Const.SUBSCRIBER_WHITELIST_LIMIT) Debug.trap(Errors.SUBSCRIBER_WHITELIST_LENGTH);
    };

    ignore do ?{
      if (options!.subscriberWhitelistRemove!.size() > Const.SUBSCRIBER_WHITELIST_LIMIT) Debug.trap(Errors.SUBSCRIBER_WHITELIST_REMOVE_LENGTH);

      for (principalId in options!.subscriberWhitelistRemove!.vals()) Set.delete(publication.subscriberWhitelist, phash, principalId);
    };

    let ?publicationInfo = Info.getPublicationInfo(state.publishersIndexId, state, (publisherId, eventName, options));

    return { publication; publicationInfo; prevPublicationInfo };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type RemovePublicationOptions = {
    purge: ?Bool;
    includeSubscriberWhitelist: ?Bool;
  };

  public type RemovePublicationResponse = {
    publicationInfo: ?Types.SharedPublication;
    prevPublicationInfo: ?Types.SharedPublication;
  };

  public type RemovePublicationParams = (publisherId: Principal, eventName: Text, options: ?RemovePublicationOptions);

  public type RemovePublicationFullParams = (caller: Principal, state: State.PublishersStoreState, params: RemovePublicationParams);

  public func removePublication((caller, state, (publisherId, eventName, options)): RemovePublicationFullParams): RemovePublicationResponse {
    if (caller != state.publishersIndexId) Debug.trap(Errors.PERMISSION_DENIED);

    if (eventName.size() > Const.EVENT_NAME_LENGTH_LIMIT) Debug.trap(Errors.EVENT_NAME_LENGTH);

    let prevPublicationInfo = Info.getPublicationInfo(state.publishersIndexId, state, (publisherId, eventName, options));

    ignore do ?{
      let publisher = Map.get(state.publishers, phash, publisherId)!;
      let publicationGroup = Map.get(state.publications, thash, eventName)!;
      let publication = Map.get(publicationGroup, phash, publisherId)!;

      if (publication.active) {
        publication.active := false;
        publisher.activePublications -= 1;
      };

      if (options!.purge!) {
        Set.delete(publisher.publications, thash, eventName);
        Map.delete(publicationGroup, phash, publisherId);

        if (Map.empty(publicationGroup)) Map.delete(state.publications, thash, eventName);
      };
    };

    let publicationInfo = Info.getPublicationInfo(state.publishersIndexId, state, (publisherId, eventName, options));

    return { publicationInfo; prevPublicationInfo };
  };
};
