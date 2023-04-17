import Const "../../../common/const";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Principal "mo:base/Principal";
import PublishersIndex "../../PublishersIndex/main";
import Stats "../../../common/stats";
import SubscribersIndex "../../SubscribersIndex/main";
import { arraySlice } "../../../utils/misc";
import { Types; State } "../../../migrations/types";

module {
  public func transferPublicationStats(state: State.BroadcastState): async* () {
    let publishersIndex = actor(Principal.toText(state.publishersIndexId)):PublishersIndex.PublishersIndex;
    var transferedSize = 0;

    let transferStats = Map.toArrayMap<(Principal, Text), State.Stats, Types.StatsEntry>(
      state.publicationStats,
      func((publisherId, eventName), stats) = ?(publisherId, eventName, Stats.share(stats)),
    );

    Map.clear(state.publicationStats);

    while (transferedSize < transferStats.size()) {
      let statsBatch = arraySlice(transferStats, ?transferedSize, ?(transferedSize + Const.STATS_BATCH_SIZE));
      var remainingStats = statsBatch;

      try {
        remainingStats := await publishersIndex.mergePublicationStats(statsBatch);
      } catch (err) {
        Debug.print(Error.message(err));
      };

      for ((publisherId, eventName, stats) in remainingStats.vals()) {
        Stats.update(state.publicationStats, publisherId, eventName, stats);
      };

      transferedSize += Const.STATS_BATCH_SIZE;
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func transferSubscriptionStats(state: State.BroadcastState): async* () {
    let subscribersIndex = actor(Principal.toText(state.subscribersIndexId)):SubscribersIndex.SubscribersIndex;
    var transferedSize = 0;

    let transferStats = Map.toArrayMap<(Principal, Text), State.Stats, Types.StatsEntry>(
      state.subscriptionStats,
      func((subscriberId, eventName), stats) = ?(subscriberId, eventName, Stats.share(stats)),
    );

    Map.clear(state.subscriptionStats);

    while (transferedSize < transferStats.size()) {
      let statsBatch = arraySlice(transferStats, ?transferedSize, ?(transferedSize + Const.STATS_BATCH_SIZE));
      var remainingStats = statsBatch;

      try {
        remainingStats := await subscribersIndex.mergeSubscriptionStats(statsBatch);
      } catch (err) {
        Debug.print(Error.message(err));
      };

      for ((subscriberId, eventName, stats) in remainingStats.vals()) {
        Stats.update(state.subscriptionStats, subscriberId, eventName, stats);
      };

      transferedSize += Const.STATS_BATCH_SIZE;
    };
  };
};
