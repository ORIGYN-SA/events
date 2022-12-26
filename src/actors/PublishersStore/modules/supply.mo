import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Info "./info";
import { Types; State } "../../../migrations/types";

module {
  public type PublicationDataResponse = {
    publisher: ?Types.SharedPublisher;
    publication: ?Types.SharedPublication;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.PublishersStoreState, deployer: Principal): {
    supplyPublicationData: (caller: Principal, publisherId: Principal, eventName: Text) -> PublicationDataResponse;
  } = object {
    let { publishers; publications } = state;

    let InfoModule = Info.init(state, deployer);

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func supplyPublicationData(caller: Principal, publisherId: Principal, eventName: Text): PublicationDataResponse {
      if (caller != deployer) Debug.trap(Errors.PERMISSION_DENIED);

      let publisher = InfoModule.getPublisherInfo(caller, publisherId, null);
      let publication = InfoModule.getPublicationInfo(caller, publisherId, eventName, ?{ includeWhitelist = ?true });

      return { publisher; publication };
    };
  };
};
