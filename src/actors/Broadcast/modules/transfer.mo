import Candy "mo:candy/types";
import Const "../../../common/const";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Inform "./inform";
import Map "mo:map/Map";
import MigrationTypes "../../../migrations/types";
import Prim "mo:prim";
import Set "mo:map/Set";
import Types "../../../common/types";
import Utils "../../../utils/misc";

module {
  let State = MigrationTypes.Current;

  let { unwrap } = Utils;

  let { nhash; thash; phash; lhash } = Map;

  let { time } = Prim;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.BroadcastState, deployer: Principal): {
    transferPublicationStats: (caller: Principal) -> ();
  } = object {
    let { events; broadcastQueue } = state;

    let InformModule = Inform.init(state, deployer);

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func transferPublicationStats(caller: Principal) {
      
    };
  };
};
