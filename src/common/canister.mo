import { Types; State } "../migrations/types";

module {
  public func share(canister: State.Canister): Types.SharedCanister {
    return {
      canisterId = canister.canisterId;
      canisterType = canister.canisterType;
      status = canister.status;
      active = canister.active;
      heapSize = canister.heapSize;
      balance = canister.balance;
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func thaw(canister: Types.SharedCanister): State.Canister {
    return {
      canisterId = canister.canisterId;
      canisterType = canister.canisterType;
      var status = canister.status;
      var active = canister.active;
      var heapSize = canister.heapSize;
      var balance = canister.balance;
    };
  };
};