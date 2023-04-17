import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Info "./info";
import Set "mo:map/Set";
import { n32hash; n64hash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type PublicationDataResponse = {
    publisher: Types.SharedPublisher;
    publication: Types.SharedPublication;
  };

  public type PublicationDataParams = (publisherId: Principal, eventName: Text);

  public type PublicationDataFullParams = (caller: Principal, state: State.PublishersStoreState, params: PublicationDataParams);

  public func supplyPublicationData((caller, state, (publisherId, eventName)): PublicationDataFullParams): PublicationDataResponse {
    if (not Set.has(state.broadcastIds, phash, caller)) Debug.trap(Errors.PERMISSION_DENIED);

    let ?publisher = (
      Info.getPublisherInfo(state.publishersIndexId, state, (publisherId, null))
    ) else {
      Debug.trap(Errors.PUBLISHER_NOT_FOUND);
    };

    let ?publication = (
      Info.getPublicationInfo(state.publishersIndexId, state, (publisherId, eventName, ?{ includeSubscriberWhitelist = ?true }))
    ) else {
      Debug.trap(Errors.PUBLICATION_NOT_FOUND);
    };

    return { publisher; publication };
  };
};
