import Map "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type BroadcastIdsResponse = [Principal];

  public type BroadcastIdsParams = ();

  public type BroadcastIdsFullParams = (caller: Principal, state: State.MainState, params: BroadcastIdsParams);

  public func getBroadcastIds((caller, state, ()): BroadcastIdsFullParams): BroadcastIdsResponse {
    return Map.toArrayMap<Principal, State.Canister, Principal>(state.canisters, func(id, canister) {
      return if (canister.active and canister.canisterType == #Broadcast) ?id else null;
    });
  };
};
