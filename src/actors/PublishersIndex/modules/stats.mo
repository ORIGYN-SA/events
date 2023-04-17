import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Principal "mo:base/Principal";
import PublishersStore "../../PublishersStore/main";
import Set "mo:map/Set";
import Stats "../../PublishersStore/modules/stats";
import Option "mo:base/Option";
import { n32hash; n64hash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type MergeStatsResponse = [Types.StatsEntry];

  public type MergeStatsParams = (statsBatch: [Types.StatsEntry]);

  public type MergeStatsFullParams = (caller: Principal, state: State.PublishersIndexState, params: MergeStatsParams);

  public func mergePublicationStats((caller, state, (statsBatch)): MergeStatsFullParams): async* MergeStatsResponse {
    if (not Set.has(state.broadcastIds, phash, caller)) Debug.trap(Errors.PERMISSION_DENIED);

    let statGroups = Map.new<Principal, Buffer.Buffer<Types.StatsEntry>>(phash);
    var remainingStats = []:[Types.StatsEntry];

    for ((publisherId, eventName, stats) in statsBatch.vals()) label iteration {
      let ?publisherStoreId = Map.get(state.publishersLocation, phash, publisherId) else break iteration;

      let ?group = Map.update<Principal, Buffer.Buffer<Types.StatsEntry>>(statGroups, phash, publisherStoreId, func(key, group) {
        return switch (group) { case (?group) ?group; case (_) ?Buffer.Buffer(1) };
      });

      group.add(publisherId, eventName, stats);
    };

    for ((publisherStoreId, group) in Map.entries(statGroups)) {
      let publisherStore = actor(Principal.toText(publisherStoreId)):PublishersStore.PublishersStore;
      let groupArray = Buffer.toArray(group);

      try {
        await publisherStore.mergePublicationStats(groupArray);
      } catch (err) {
        Debug.print(Error.message(err));

        remainingStats := Array.append(remainingStats, groupArray);
      };
    };

    return remainingStats;
  };
};
