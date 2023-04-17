import Map "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type BroadcastIdsResponse = {
    broadcastIds: [Principal];
    activeBroadcastIds: [Principal];
    broadcastVersion: Nat64;
  };

  public type BroadcastIdsParams = ();

  public type BroadcastIdsFullParams = (caller: Principal, state: State.MainState, params: BroadcastIdsParams);

  public func getBroadcastIds((caller, state, ()): BroadcastIdsFullParams): BroadcastIdsResponse {
    let broadcastIds = Map.toArrayMap<Principal, State.Canister, Principal>(state.canisters, func(id, canister) {
      return if (canister.canisterType == #Broadcast) ?id else null;
    });

    let activeBroadcastIds = Map.toArrayMap<Principal, State.Canister, Principal>(state.canisters, func(id, canister) {
      return if (canister.active and canister.canisterType == #Broadcast) ?id else null;
    });

    return { broadcastIds; activeBroadcastIds; broadcastVersion = state.broadcastVersion };
  };
};
