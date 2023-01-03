import Buffer "mo:base/Buffer";
import Const "../../../common/const";
import Debug "mo:base/Debug";
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

    let transferStats = Map.toArrayMap<(Principal, Text), State.Stats, (Principal, Text, Types.SharedStats)>(
      state.publicationStats,
      func((publisherId, eventName), stats) = ?(publisherId, eventName, Stats.share(stats)),
    );

    var transferedSize = 0;

    Map.clear(state.publicationStats);

    while (transferedSize < transferStats.size()) {
      let statsBatch = arraySlice(transferStats, ?transferedSize, ?(transferedSize + Const.STATS_BATCH_SIZE));

      var remainingStats = statsBatch;

      try { remainingStats := await publishersIndex.transferPublicationStats(statsBatch) } catch (_) {};

      for ((publisherId, eventName, stats) in remainingStats.vals()) {
        Stats.update(state.publicationStats, publisherId, eventName, stats);
      };

      transferedSize += Const.STATS_BATCH_SIZE;
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func transferSubscriptionStats(state: State.BroadcastState): async* () {
    let subscribersIndex = actor(Principal.toText(state.subscribersIndexId)):SubscribersIndex.SubscribersIndex;

    let transferStats = Map.toArrayMap<(Principal, Text), State.Stats, (Principal, Text, Types.SharedStats)>(
      state.subscriptionStats,
      func((subscriberId, eventName), stats) = ?(subscriberId, eventName, Stats.share(stats)),
    );

    var transferedSize = 0;

    Map.clear(state.subscriptionStats);

    while (transferedSize < transferStats.size()) {
      let statsBatch = arraySlice(transferStats, ?transferedSize, ?(transferedSize + Const.STATS_BATCH_SIZE));

      var remainingStats = statsBatch;

      try { remainingStats := await subscribersIndex.transferSubscriptionStats(statsBatch) } catch (_) {};

      for ((subscriberId, eventName, stats) in remainingStats.vals()) {
        Stats.update(state.subscriptionStats, subscriberId, eventName, stats);
      };

      transferedSize += Const.STATS_BATCH_SIZE;
    };
  };
};
