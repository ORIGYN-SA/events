import Buffer "mo:base/Buffer";
import Candy "mo:candy/types";
import CandyUtils "mo:candy_utils/CandyUtils";
import Const "../../../common/const";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Inform "./inform";
import Map "mo:map/Map";
import MigrationTypes "../../../migrations/types";
import Prim "mo:prim";
import Set "mo:map/Set";
import Types "../../../common/types";

module {
  let State = MigrationTypes.Current;

  let { get } = CandyUtils;

  let { nhash; thash; phash; lhash } = Map;

  let { nat8ToNat } = Prim;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type PublicationDataResponse = {
    publisher: ?Types.SharedPublisher;
    publication: ?Types.SharedPublication;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.PublishersStoreState, deployer: Principal): {
    supplyPublicationData: (caller: Principal, publisherId: Principal, eventName: Text) -> PublicationDataResponse;
  } = object {
    let { publishers; publications } = state;

    let InformModule = Inform.init(state, deployer);

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func supplyPublicationData(caller: Principal, publisherId: Principal, eventName: Text): PublicationDataResponse {
      if (caller != deployer) Debug.trap(Errors.PERMISSION_DENIED);

      let publisher = InformModule.getPublisherInfo(caller, publisherId, null);
      let publication = InformModule.getPublicationInfo(caller, publisherId, eventName, ?{ includeWhitelist = ?true });

      return { publisher; publication };
    };
  };
};
