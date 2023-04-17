import Map "mo:map/Map";
import Set "mo:map/Set";
import { n32hash; n64hash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public func add(state: State.BroadcastState, event: State.Event, priprity: Types.EventPriority) {
    if (Map.has(state.queuedEvents, n64hash, event.id)) return;

    let broadcastQueue = if (priprity == #Primary) state.primaryBroadcastQueue else state.secondaryBroadcastQueue;
    let broadcastGroups = if (priprity == #Primary) state.primaryBroadcastGroups else state.secondaryBroadcastGroups;

    let ?groupId = Map.update<Principal, Nat32>(broadcastGroups, phash, event.publisherId, func(key, groupId) = switch (groupId) {
      case (?groupId) ?(groupId + 1);
      case (_) switch (Map.peek(broadcastGroups)) { case (?(key, firstGroupId)) ?firstGroupId; case (_) ?0 };
    });

    let ?group = Map.update<Nat32, State.BroadcastGroup>(broadcastQueue, n32hash, groupId, func(key, group) {
      return switch (group) { case (?group) ?group; case (_) ?Set.new(n64hash) };
    });

    Map.set(state.queuedEvents, n64hash, event.id, groupId);
    Set.add(group, n64hash, event.id);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func remove(state: State.BroadcastState, event: State.Event) {
    let ?groupId = Map.remove(state.queuedEvents, n64hash, event.id) else return;

    label removePrimary {
      let ?primaryGroup = Map.get(state.primaryBroadcastQueue, n32hash, groupId) else break removePrimary;

      if (Set.remove(primaryGroup, n64hash, event.id)) {
        if (Map.get(state.primaryBroadcastGroups, phash, event.publisherId) == ?groupId) {
          Map.delete(state.primaryBroadcastGroups, phash, event.publisherId);
        };

        loop {
          let ?(id, firstGroup) = Map.peek(state.primaryBroadcastQueue) else break removePrimary;

          if (Set.empty(firstGroup)) ignore Map.pop(state.primaryBroadcastQueue) else break removePrimary;
        };
      };
    };

    label removeSecondary {
      let ?secondaryGroup = Map.get(state.secondaryBroadcastQueue, n32hash, groupId) else break removeSecondary;

      if (Set.remove(secondaryGroup, n64hash, event.id)) {
        if (Map.get(state.secondaryBroadcastGroups, phash, event.publisherId) == ?groupId) {
          Map.delete(state.secondaryBroadcastGroups, phash, event.publisherId);
        };

        loop {
          let ?(id, firstGroup) = Map.peek(state.secondaryBroadcastQueue) else break removeSecondary;

          if (Set.empty(firstGroup)) ignore Map.pop(state.secondaryBroadcastQueue) else break removeSecondary;
        };
      };
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func next(state: State.BroadcastState): ?State.Event {
    let broadcastQueue = if (Map.empty(state.primaryBroadcastQueue)) state.secondaryBroadcastQueue else state.primaryBroadcastQueue;

    let ?(key, group) = Map.peek(broadcastQueue) else return null;

    let ?eventId = Set.peek(group) else return null;

    return Map.get(state.events, n64hash, eventId);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func empty(state: State.BroadcastState): Bool {
    return Map.empty(state.primaryBroadcastQueue) and Map.empty(state.secondaryBroadcastQueue);
  };
};
