import MigrationTypes "./types";
import V0_1_0 "./00-01-00-initial";

module {
  let upgrades = [
    V0_1_0.upgrade,
  ];

  let downgrades = [
    V0_1_0.downgrade,
  ];

  func getMigrationId(state: MigrationTypes.StateList): Nat {
    return switch (state) {
      case (#v0_0_0(_)) 0;
      case (#v0_1_0(_)) 1;
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public let defaultArgs: MigrationTypes.Args = {
    canisters = [];
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func migrate(
    prevState: MigrationTypes.StateList,
    nextState: MigrationTypes.StateList,
    args: MigrationTypes.Args,
  ): MigrationTypes.StateList {
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
