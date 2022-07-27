import Map "mo:hashmap_4_0_0/Map";
import Set "mo:hashmap_4_0_0/Set";
import MigrationTypes "../types";

module {
  public func upgrade(migrationState: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    let #v0_0_0(#data(state)) = migrationState;

    return #v0_1_0(#data({
      var admins = Set.new();
      var eventId = 1;
      var subscribers = Map.new();
      var events = Map.new();
    }));
  };

  public func downgrade(migrationState: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    let #v0_1_0(#data(state)) = migrationState;

    return #v0_0_0(#data);
  };
};