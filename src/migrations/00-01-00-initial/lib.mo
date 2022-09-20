import Map "mo:map_8_0_0_alpha_5/Map";
import Set "mo:map_8_0_0_alpha_5/Set";
import Prim "mo:prim";
import MigrationTypes "../types";

module {
  let { nhash; thash; phash } = Map;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func upgrade(migrationState: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    let state = switch (migrationState) { case (#v0_0_0(#data(state))) state; case (_) Prim.trap("Unexpected migration state") };

    return #v0_1_0(#data({
      var eventId = 1;
      var broadcastActive = false;
      var nextBroadcastTime = 0;
      admins = Set.new(phash);
      publishers = Map.new(phash);
      publications = Map.new(thash);
      subscribers = Map.new(phash);
      subscriptions = Map.new(thash);
      events = Map.new(nhash);
    }));
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func downgrade(migrationState: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    let state = switch (migrationState) { case (#v0_1_0(#data(state))) state; case (_) Prim.trap("Unexpected migration state") };

    return #v0_0_0(#data);
  };
};
