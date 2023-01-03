import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public func init(state: State.MainState): async* () {
    if (not Map.find(state.canisters, func(key, canister) = canister.canisterType == #PublishersIndex)) {
      let publishersIndex
    };

    state.initialized := true;
  };
};
