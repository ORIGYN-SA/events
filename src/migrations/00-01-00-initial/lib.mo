import Debug "mo:base/Debug";
import Map "mo:map_8_1_0/Map";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Set "mo:map_8_1_0/Set";
import MigrationTypes "../types";
import { n32hash; n64hash; thash; phash } "mo:map_8_1_0/Map";
import { pthash } "./utils";

module {
  public func upgrade(migrationState: MigrationTypes.StateList, args: MigrationTypes.Args): MigrationTypes.StateList {
    let state = switch (migrationState) { case (#v0_0_0(#data(state))) state; case (_) Debug.trap("Unexpected migration state") };

    switch (state) {
      case (#Broadcast(state)) {
        let ?mainId = args.mainId else Debug.trap("Argument mainId is not present");
        let ?publishersIndexId = args.publishersIndexId else Debug.trap("Argument publishersIndexId is not present");
        let ?subscribersIndexId = args.subscribersIndexId else Debug.trap("Argument subscribersIndexId is not present");
        let ?subscribersStoreIds = args.subscribersStoreIds else Debug.trap("Argument subscribersStoreIds is not present");
        let ?broadcastVersion = args.broadcastVersion else Debug.trap("Argument broadcastVersion is not present");

        return #v0_1_0(#data(#Broadcast({
          mainId = mainId;
          publishersIndexId = publishersIndexId;
          subscribersIndexId = subscribersIndexId;
          var subscribersStoreIds = Set.fromIter(subscribersStoreIds.vals(), phash);
          var active = true;
          var eventId = 0;
          var broadcastActive = false;
          var maxQueueSize = 0;
          var broadcastVersion = broadcastVersion;
          var broadcastQueued = false;
          var randomSeed = 0;
          events = Map.new(n64hash);
          queuedEvents = Map.new(n64hash);
          primaryBroadcastQueue = Map.new(n32hash);
          secondaryBroadcastQueue = Map.new(n32hash);
          primaryBroadcastGroups = Map.new(phash);
          secondaryBroadcastGroups = Map.new(phash);
          publicationStats = Map.new(pthash);
          publicationTransferStats = Map.new(pthash);
          subscriptionStats = Map.new(pthash);
          subscriptionTransferStats = Map.new(pthash);
        })));
      };

      ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

      case (#Main(state)) {
        let mainId = Principal.fromBlob(""); // args.mainId else Debug.trap("Argument mainId is not present");
        let ?deployer = args.deployer else Debug.trap("Argument deployer is not present");

        return #v0_1_0(#data(#Main({
          mainId = mainId;
          var publishersIndexId = Principal.fromBlob("");
          var subscribersIndexId = Principal.fromBlob("");
          var initialized = false;
          var broadcastSynced = true;
          var publishersStoreSynced = true;
          var subscribersStoreSynced = true;
          var broadcastVersion = 1;
          var status = #Running;
          admins = Set.fromIter([deployer].vals(), phash);
          canisters = Map.new(phash);
        })));
      };

      ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

      case (#PublishersIndex(state)) {
        let ?mainId = args.mainId else Debug.trap("Argument mainId is not present");
        let broadcastIds = Option.get(args.broadcastIds, []);

        return #v0_1_0(#data(#PublishersIndex({
          mainId = mainId;
          var publishersStoreId = null;
          broadcastIds = Set.fromIter(broadcastIds.vals(), phash);
          publishersLocation = Map.new(phash);
        })));
      };

      ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

      case (#PublishersStore(state)) {
        let ?mainId = args.mainId else Debug.trap("Argument mainId is not present");
        let ?publishersIndexId = args.publishersIndexId else Debug.trap("Argument publishersIndexId is not present");
        let broadcastIds = Option.get(args.broadcastIds, []);

        return #v0_1_0(#data(#PublishersStore({
          mainId = mainId;
          publishersIndexId = publishersIndexId;
          broadcastIds = Set.fromIter(broadcastIds.vals(), phash);
          publishers = Map.new(phash);
          publications = Map.new(thash);
        })));
      };

      ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

      case (#SubscribersIndex(state)) {
        let ?mainId = args.mainId else Debug.trap("Argument mainId is not present");
        let broadcastIds = Option.get(args.broadcastIds, []);

        return #v0_1_0(#data(#SubscribersIndex({
          mainId = mainId;
          var subscribersStoreId = null;
          broadcastIds = Set.fromIter(broadcastIds.vals(), phash);
          subscribersLocation = Map.new(phash);
        })));
      };

      ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

      case (#SubscribersStore(state)) {
        let ?mainId = args.mainId else Debug.trap("Argument mainId is not present");
        let ?subscribersIndexId = args.subscribersIndexId else Debug.trap("Argument subscribersIndexId is not present");
        let broadcastIds = Option.get(args.broadcastIds, []);

        return #v0_1_0(#data(#SubscribersStore({
          mainId = mainId;
          subscribersIndexId = subscribersIndexId;
          broadcastIds = Set.fromIter(broadcastIds.vals(), phash);
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
