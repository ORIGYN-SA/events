import Debug "mo:base/Debug";
import Map "mo:map_8_0_0_rc_2/Map";
import Set "mo:map_8_0_0_rc_2/Set";
import MigrationTypes "../types";
import Utils "./utils"

module {
  public func upgrade(migrationState: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    let state = switch (migrationState) { case (#v0_0_0(#data(state))) state; case (_) Debug.trap("Unexpected migration state") };

    switch (state) {
      case (#Broadcast(state)) {
        return #v0_1_0(#data(#Broadcast({
          var eventId = 0;
          var broadcastActive = false;
          var maxQueueSize = 0;
          events = Map.new(Map.nhash);
          broadcastQueue = Set.new(Set.nhash);
          publicationStatsBatch = Map.new(Utils.pthash);
          subscriptionStatsBatch = Map.new(Utils.pthash);
        })));
      };

      case (#Main(state)) {
        return #v0_1_0(#data(#Main({
          canisters = Map.new(Map.phash);
          broadcastCanisters = Map.new(Map.phash);
          publishersStoreCanisters = Map.new(Map.phash);
          subscribersStoreCanisters = Map.new(Map.phash);
        })));
      };

      case (#PublishersStore(state)) {
        return #v0_1_0(#data(#PublishersStore({
          publishers = Map.new(Map.phash);
          publications = Map.new(Map.thash);
        })));
      };

      case (#SubscribersStore(state)) {
        return #v0_1_0(#data(#SubscribersStore({
          subscribers = Map.new(Map.phash);
          subscriptions = Map.new(Map.thash);
        })));
      };
    };
  };

  public func downgrade(migrationState: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    let state = switch (migrationState) { case (#v0_1_0(#data(state))) state; case (_) Debug.trap("Unexpected migration state") };

    switch (state) {
      case (#Broadcast(state)) {
        return #v0_0_0(#data(#Broadcast));
      };

      case (#Main(state)) {
        return #v0_0_0(#data(#Main));
      };

      case (#PublishersStore(state)) {
        return #v0_0_0(#data(#PublishersStore));
      };

      case (#SubscribersStore(state)) {
        return #v0_0_0(#data(#SubscribersStore));
      };
    };
  };
};
