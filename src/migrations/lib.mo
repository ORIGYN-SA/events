import Migration001 "./001-initial";
import Migration002 "./002-one-time-calls";
import MigrationTypes "./types";

module {
  let upgrades = [
    Migration001.upgrade,
    Migration002.upgrade,
  ];

  let downgrades = [
    Migration001.downgrade,
    Migration002.downgrade,
  ];

  func getMigrationId(state: MigrationTypes.State): Nat {
    return switch (state) {
      case (#state000(_)) 0;
      case (#state001(_)) 1;
      case (#state002(_)) 2;
    };
  };

  public func migrate(prevState: MigrationTypes.State, nextState: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    var state = prevState;
    var migrationId = getMigrationId(prevState);

    let nextMigrationId = getMigrationId(nextState);

    while (migrationId != nextMigrationId) {
      let migrate = if (nextMigrationId > migrationId) upgrades[migrationId] else downgrades[migrationId - 1];

      migrationId := if (nextMigrationId > migrationId) migrationId + 1 else migrationId - 1;

      state := migrate(state, args);
    };

    return state;
  };
};