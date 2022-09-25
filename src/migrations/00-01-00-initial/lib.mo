import Debug "mo:base/Debug";
import Map "mo:map_4_0_0/Map";
import Set "mo:map_4_0_0/Set";
import MigrationTypes "../types";

module {
  public func upgrade(migrationState: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    let state = switch (migrationState) { case (#v0_0_0(#data(state))) state; case (_) Debug.trap("Unexpected migration state") };

    return #v0_1_0(#data({
      var admins = Set.new();
      var eventId = 1;
      var subscribers = Map.new();
      var events = Map.new();
    }));
  };

  public func downgrade(migrationState: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    let state = switch (migrationState) { case (#v0_1_0(#data(state))) state; case (_) Debug.trap("Unexpected migration state") };

    return #v0_0_0(#data);
  };
};