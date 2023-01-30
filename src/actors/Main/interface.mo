import Config "./modules/config";
import Manage "./modules/manage";

module {
  public type Main = actor {
    getBroadcastIds: query (params: Config.BroadcastIdsParams) -> async Config.BroadcastIdsResponse;
  };
};
