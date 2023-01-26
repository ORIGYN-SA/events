import Config "./modules/config";
import Manage "./modules/manage";

module {
  public type Main = actor {
    getBroadcastIds: query (params: Config.BroadcastIdsParams) -> async Config.BroadcastIdsResponse;
    requestCycles: shared (params: Manage.RequestCyclesParams) -> async Manage.RequestCyclesResponse;
    addCycles: query () -> async Nat;
  };
};
