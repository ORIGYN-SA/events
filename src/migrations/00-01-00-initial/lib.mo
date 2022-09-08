import Map "mo:map_8_0_0_alpha_5/Map";
import Set "mo:map_8_0_0_alpha_5/Set";
import Prim "mo:prim";
import MigrationTypes "../types";
import Utils "./utils"

module {
  let { pthash } = Utils;

  let { nhash; phash } = Map;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func upgrade(migrationState: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    let state = switch (migrationState) { case (#v0_0_0(#data(state))) state; case (_) Prim.trap("Unexpected migration state") };

    return #v0_1_0(#data({
      var eventId = 1;
      var nextBroadcastTime = 0;
      admins = Set.new(phash);
      subscribers = Map.new(phash);
      subscriptions = Map.new(pthash);
      publishers = Map.new(phash);
      publications = Map.new(pthash);
      events = Map.new(nhash);
    }));
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func downgrade(migrationState: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    let state = switch (migrationState) { case (#v0_1_0(#data(state))) state; case (_) Prim.trap("Unexpected migration state") };

    return #v0_0_0(#data);
  };
};
