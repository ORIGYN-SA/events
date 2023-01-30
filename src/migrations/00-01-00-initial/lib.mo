import Debug "mo:base/Debug";
import Map "mo:map_8_0_0_rc_2/Map";
import Set "mo:map_8_0_0_rc_2/Set";
import MigrationTypes "../types";
import { nhash; thash; phash } "mo:map_8_0_0_rc_2/Map";
import { take; pthash } "./utils";

module {
  public func upgrade(migrationState: MigrationTypes.StateList, args: MigrationTypes.Args): MigrationTypes.StateList {
    let state = switch (migrationState) { case (#v0_0_0(#data(state))) state; case (_) Debug.trap("Unexpected migration state") };

    switch (state) {
      case (#Broadcast(state)) {
        return #v0_1_0(#data(#Broadcast({
          mainId = take(args.mainId, "Argument mainId is not present");
          publishersIndexId = take(args.publishersIndexId, "Argument publishersIndexId is not present");
          subscribersIndexId = take(args.subscribersIndexId, "Argument subscribersIndexId is not present");
          var subscribersStoreIds = Set.fromIter(args.subscribersStoreIds.vals(), phash);
          var active = true;
          var eventId = 0;
          var broadcastActive = false;
          var maxQueueSize = 0;
          var broadcastIndex = 1;
          var broadcastTimerId = 0;
          var randomSeed = 0;
          events = Map.new(nhash);
          broadcastQueue = Set.new(nhash);
          publicationStats = Map.new(pthash);
          subscriptionStats = Map.new(pthash);
        })));
      };

      case (#Main(state)) {
        return #v0_1_0(#data(#Main({
          var initialized = false;
          var broadcastIndex = 1;
          canisters = Map.new(phash);
        })));
      };

      case (#PublishersIndex(state)) {
        return #v0_1_0(#data(#PublishersIndex({
          mainId = take(args.mainId, "Argument mainId is not present");
          var publishersStoreId = null;
          broadcastIds = Set.fromIter(args.broadcastIds.vals(), phash);
          publishersLocation = Map.new(phash);
        })));
      };

      case (#PublishersStore(state)) {
        return #v0_1_0(#data(#PublishersStore({
          mainId = take(args.mainId, "Argument mainId is not present");
          publishersIndexId = take(args.publishersIndexId, "Argument publishersIndexId is not present");
          broadcastIds = Set.fromIter(args.broadcastIds.vals(), phash);
          publishers = Map.new(phash);
          publications = Map.new(thash);
        })));
      };

      case (#SubscribersIndex(state)) {
        return #v0_1_0(#data(#SubscribersIndex({
          mainId = take(args.mainId, "Argument mainId is not present");
          var subscribersStoreId = null;
          broadcastIds = Set.fromIter(args.broadcastIds.vals(), phash);
          subscribersLocation = Map.new(phash);
        })));
      };

      case (#SubscribersStore(state)) {
        return #v0_1_0(#data(#SubscribersStore({
          mainId = take(args.mainId, "Argument mainId is not present");
          subscribersIndexId = take(args.subscribersIndexId, "Argument subscribersIndexId is not present");
          broadcastIds = Set.fromIter(args.broadcastIds.vals(), phash);
          subscribers = Map.new(phash);
          subscriptions = Map.new(thash);
        })));
      };
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func downgrade(migrationState: MigrationTypes.StateList, args: MigrationTypes.Args): MigrationTypes.StateList {
    let state = switch (migrationState) { case (#v0_1_0(#data(state))) state; case (_) Debug.trap("Unexpected migration state") };

    switch (state) {
      case (#Broadcast(state)) {
        return #v0_0_0(#data(#Broadcast));
      };

      case (#Main(state)) {
        return #v0_0_0(#data(#Main));
      };

      case (#PublishersIndex(state)) {
        return #v0_0_0(#data(#PublishersIndex));
      };

      case (#PublishersStore(state)) {
        return #v0_0_0(#data(#PublishersStore));
      };

      case (#SubscribersIndex(state)) {
        return #v0_0_0(#data(#SubscribersIndex));
      };

      case (#SubscribersStore(state)) {
        return #v0_0_0(#data(#SubscribersStore));
      };
    };
  };
};
