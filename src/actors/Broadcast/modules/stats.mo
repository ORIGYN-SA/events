import Buffer "mo:base/Buffer";
import Const "../../../common/const";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Principal "mo:base/Principal";
import Stats "../../../common/stats";
import PublishersStore "../../PublishersStore/main";
import { arraySlice } "../../../utils/misc";
import { Types; State } "../../../migrations/types";

module {
  public type TransferStats = (Principal, Text, Types.SharedStats);

  public type ConsumedStats = (Principal, Text);

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.BroadcastState, deployer: Principal): {
    transferPublicationStats: () -> async ();
  } = object {
    let { canisters; publicationStats } = state;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func transferPublicationStats(): async () {
      let transferFutures = Buffer.Buffer<async [ConsumedStats]>(0);

      let transferStats = Map.toArrayMap<(Principal, Text), State.Stats, TransferStats>(publicationStats, func((publisherId, eventName), stats) {
        return ?(publisherId, eventName, Stats.share(stats));
      });

      var transferedSize = 0;

      Map.clear(state.publicationStats);

      while (transferedSize < transferStats.size()) {
        let statsBatch = arraySlice(transferStats, ?transferedSize, ?(transferedSize + Const.STATS_BATCH_SIZE));

        for (canister in Map.vals(canisters)) if (canister.canisterType == #PublishersStore) {
          let publishersStore = actor(Principal.toText(canister.canisterId)):PublishersStore.PublishersStore;

          transferFutures.add(publishersStore.consumePublicationStats(statsBatch));
        };

        transferedSize += Const.STATS_BATCH_SIZE;
      }
    };
  };
};
