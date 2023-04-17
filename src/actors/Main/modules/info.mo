import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Set "mo:map/Set";
import { n32hash; n64hash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type UpgradeStatusResponse = {
    main: State.CanisterStatus;
    running: Nat;
    stopped: Nat;
    upgrading: Nat;
    upgraded: Nat;
    total: Nat;
  };

  public type UpgradeStatusParams = ();

  public type UpgradeStatusFullParams = (caller: Principal, state: State.MainState, params: UpgradeStatusParams);

  public func getUpgradeStatus((caller, state, ()): UpgradeStatusFullParams): UpgradeStatusResponse {
    if (not Set.has(state.admins, phash, caller)) Debug.trap(Errors.PERMISSION_DENIED);

    var running = 0;
    var stopped = 0;
    var upgrading = 0;
    var upgraded = 0;

    for (canister in Map.vals(state.canisters)) {
      switch (canister.status) {
        case (#Running) running += 1;
        case (#Stopped) stopped += 1;
        case (#Upgrading) upgrading += 1;
        case (#Upgraded) upgraded += 1;
        case (_) {};
      };
    };

    return {
      main = state.status;
      running = running;
      stopped = stopped;
      upgrading = upgrading;
      upgraded = upgraded;
      total = Map.size(state.canisters);
    };
  };
};
