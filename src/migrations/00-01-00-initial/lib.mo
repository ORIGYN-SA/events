import Debug "mo:base/Debug";
import Map "mo:map_8_0_0_rc_2/Map";
import Set "mo:map_8_0_0_rc_2/Set";
import MigrationTypes "../types";
import State "./state";
import Types "./types";
import Utils "./utils";

module {
  public func upgrade(migrationState: MigrationTypes.StateList, args: MigrationTypes.Args): MigrationTypes.StateList {
    let state = switch (migrationState) { case (#v0_0_0(#data(state))) state; case (_) Debug.trap("Unexpected migration state") };

    let canisters = Map.fromIterMap<Principal, State.Canister, Types.SharedCanister>(args.canisters.vals(), Map.phash, func(canister) {
      return ?(canister.canisterId, {
        canisterId = canister.canisterId;
        canisterType = canister.canisterType;
        var heapSize = canister.heapSize;
        var balance = canister.balance;
      });
    });

    switch (state) {
      case (#Broadcast(state)) {
        return #v0_1_0(#data(#Broadcast({
          var eventId = 0;
          var broadcastActive = false;
          var maxQueueSize = 0;
          canisters = canisters;
          events = Map.new(Map.nhash);
          broadcastQueue = Set.new(Set.nhash);
          publicationStats = Map.new(Utils.pthash);
          subscriptionStats = Map.new(Utils.pthash);
        })));
      };

      case (#Main(state)) {
        return #v0_1_0(#data(#Main({
          canisters = canisters;
        })));
      };

      case (#PublishersStore(state)) {
        return #v0_1_0(#data(#PublishersStore({
          canisters = canisters;
          publishers = Map.new(Map.phash);
          publications = Map.new(Map.thash);
        })));
      };

      case (#SubscribersStore(state)) {
        return #v0_1_0(#data(#SubscribersStore({
          canisters = canisters;
          subscribers = Map.new(Map.phash);
          subscriptions = Map.new(Map.thash);
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

      case (#PublishersStore(state)) {
        return #v0_0_0(#data(#PublishersStore));
      };

      case (#SubscribersStore(state)) {
        return #v0_0_0(#data(#SubscribersStore));
      };
    };
  };
};
