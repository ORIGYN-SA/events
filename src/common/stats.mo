import MigrationTypes "../migrations/types";
import Types "./types";

module {
  let State = MigrationTypes.Current;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func defaultStats(): State.Stats {
    return {
      var numberOfEvents = 0;
      var numberOfNotifications = 0;
      var numberOfResendNotifications = 0;
      var numberOfRequestedNotifications = 0;
      var numberOfConfirmations = 0;
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func shareStats(stats: State.Stats): Types.SharedStats {
    return {
      numberOfEvents = stats.numberOfEvents;
      numberOfNotifications = stats.numberOfNotifications;
      numberOfResendNotifications = stats.numberOfResendNotifications;
      numberOfRequestedNotifications = stats.numberOfRequestedNotifications;
      numberOfConfirmations = stats.numberOfConfirmations;
    };
  };
};
