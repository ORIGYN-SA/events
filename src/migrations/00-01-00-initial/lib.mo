import Debug "mo:base/Debug";
import Map "mo:map_8_0_0_rc_2/Map";
import Principal "mo:base/Principal";
import Set "mo:map_8_0_0_rc_2/Set";
import MigrationTypes "../types";
import { get = coalesce } "mo:base/Option";
import { nhash; thash; phash } "mo:map_8_0_0_rc_2/Map";
import { take; pthash } "./utils";

module {
  public func upgrade(migrationState: MigrationTypes.StateList, args: MigrationTypes.Args): MigrationTypes.StateList {
    let state = switch (migrationState) { case (#v0_0_0(#data(state))) state; case (_) Debug.trap("Unexpected migration state") };

    switch (state) {
      case (#Broadcast(state)) {
        let options = {
          mainId = take(args.mainId, "Argument mainId is not present");
          publishersIndexId = take(args.publishersIndexId, "Argument publishersIndexId is not present");
          subscribersIndexId = take(args.subscribersIndexId, "Argument subscribersIndexId is not present");
          subscribersStoreIds = take(args.subscribersStoreIds, "Argument subscribersStoreIds is not present");
          broadcastVersion = take(args.broadcastVersion, "Argument broadcastVersion is not present");
        };

        return #v0_1_0(#data(#Broadcast({
          mainId = options.mainId;
          publishersIndexId = options.publishersIndexId;
          subscribersIndexId = options.subscribersIndexId;
          var subscribersStoreIds = Set.fromIter(options.subscribersStoreIds.vals(), phash);
          var active = true;
          var eventId = 0;
          var broadcastActive = false;
          var maxQueueSize = 0;
          var broadcastVersion = options.broadcastVersion;
          var broadcastQueued = false;
          var randomSeed = 0;
          events = Map.new(nhash);
          broadcastQueue = Set.new(nhash);
          publicationStats = Map.new(pthash);
          publicationTransferStats = Map.new(pthash);
          subscriptionStats = Map.new(pthash);
          subscriptionTransferStats = Map.new(pthash);
        })));
      };

      ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

      case (#Main(state)) {
        let options = {
          mainId = Principal.fromBlob(""); // take(args.mainId, "Argument mainId is not present");
          deployer = take(args.deployer, "Argument deployer is not present");
        };

        return #v0_1_0(#data(#Main({
          mainId = options.mainId;
          var publishersIndexId = Principal.fromBlob("");
          var subscribersIndexId = Principal.fromBlob("");
          var initialized = false;
          var broadcastVersion = 1;
          var status = #Running;
          admins = Set.fromIter([options.deployer].vals(), phash);
          canisters = Map.new(phash);
        })));
      };

      ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

      case (#PublishersIndex(state)) {
        let options = {
          mainId = take(args.mainId, "Argument mainId is not present");
          broadcastIds = coalesce(args.broadcastIds, []);
        };

        return #v0_1_0(#data(#PublishersIndex({
          mainId = options.mainId;
          var publishersStoreId = null;
          broadcastIds = Set.fromIter(options.broadcastIds.vals(), phash);
          publishersLocation = Map.new(phash);
        })));
      };

      ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

      case (#PublishersStore(state)) {
        let options = {
          mainId = take(args.mainId, "Argument mainId is not present");
          publishersIndexId = take(args.publishersIndexId, "Argument publishersIndexId is not present");
          broadcastIds = coalesce(args.broadcastIds, []);
        };

        return #v0_1_0(#data(#PublishersStore({
          mainId = options.mainId;
          publishersIndexId = options.publishersIndexId;
          broadcastIds = Set.fromIter(options.broadcastIds.vals(), phash);
          publishers = Map.new(phash);
          publications = Map.new(thash);
        })));
      };

      ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

      case (#SubscribersIndex(state)) {
        let options = {
          mainId = take(args.mainId, "Argument mainId is not present");
          broadcastIds = coalesce(args.broadcastIds, []);
        };

        return #v0_1_0(#data(#SubscribersIndex({
          mainId = options.mainId;
          var subscribersStoreId = null;
          broadcastIds = Set.fromIter(options.broadcastIds.vals(), phash);
          subscribersLocation = Map.new(phash);
        })));
      };

      ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

      case (#SubscribersStore(state)) {
        let options = {
          mainId = take(args.mainId, "Argument mainId is not present");
          subscribersIndexId = take(args.subscribersIndexId, "Argument subscribersIndexId is not present");
          broadcastIds = coalesce(args.broadcastIds, []);
        };

        return #v0_1_0(#data(#SubscribersStore({
          mainId = options.mainId;
          subscribersIndexId = options.subscribersIndexId;
          broadcastIds = Set.fromIter(options.broadcastIds.vals(), phash);
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
