import Buffer "mo:base/Buffer";
import Const "../../../common/const";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Principal "mo:base/Principal";
import PublishersStore "../../PublishersStore/main";
import Stats "../../../common/stats";
import { arraySlice } "../../../utils/misc";
import { Types; State } "../../../migrations/types";

module {
  public type ConfirmEventResponse = ();

  public type ConfirmEventParams = ();

  public type ConfirmEventFullParams = (caller: Principal, state: State.BroadcastState, params: ConfirmEventParams);

  public func transferPublicationStats((caller, state, ()): ConfirmEventFullParams): async ConfirmEventResponse {
    let transferFutures = Buffer.Buffer<async [(Principal, Text)]>(0);

    let transferStats = Map.toArrayMap<(Principal, Text), State.Stats, (Principal, Text, Types.SharedStats)>(
      state.publicationStats,
      func((publisherId, eventName), stats) = ?(publisherId, eventName, Stats.share(stats)),
    );

    var transferedSize = 0;

    Map.clear(state.publicationStats);

    while (transferedSize < transferStats.size()) {
      let statsBatch = arraySlice(transferStats, ?transferedSize, ?(transferedSize + Const.STATS_BATCH_SIZE));

      // for (canister in Map.vals(canisters)) if (canister.canisterType == #PublishersStore) {
      //   let publishersStore = actor(Principal.toText(canister.canisterId)):PublishersStore.PublishersStore;

      //   transferFutures.add(publishersStore.consumePublicationStats(statsBatch));
      // };

      transferedSize += Const.STATS_BATCH_SIZE;
    }
  };
};
