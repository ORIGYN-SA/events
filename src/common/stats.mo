import Map "mo:map/Map";
import { fallback; pthash } "../utils/misc";
import { Types; State } "../migrations/types";

module {
  public let empty: Types.SharedStats = {
    numberOfEvents = 0;
    numberOfNotifications = 0;
    numberOfResendNotifications = 0;
    numberOfRequestedNotifications = 0;
    numberOfConfirmations = 0;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func build(): State.Stats {
    return {
      var numberOfEvents = 0;
      var numberOfNotifications = 0;
      var numberOfResendNotifications = 0;
      var numberOfRequestedNotifications = 0;
      var numberOfConfirmations = 0;
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func share(stats: State.Stats): Types.SharedStats {
    return {
      numberOfEvents = stats.numberOfEvents;
      numberOfNotifications = stats.numberOfNotifications;
      numberOfResendNotifications = stats.numberOfResendNotifications;
      numberOfRequestedNotifications = stats.numberOfRequestedNotifications;
      numberOfConfirmations = stats.numberOfConfirmations;
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func thaw(stats: Types.SharedStats): State.Stats {
    return {
      var numberOfEvents = stats.numberOfEvents;
      var numberOfNotifications = stats.numberOfNotifications;
      var numberOfResendNotifications = stats.numberOfResendNotifications;
      var numberOfRequestedNotifications = stats.numberOfRequestedNotifications;
      var numberOfConfirmations = stats.numberOfConfirmations;
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func merge(stats: State.Stats, newStats: Types.SharedStats) {
    stats.numberOfEvents += newStats.numberOfEvents;
    stats.numberOfNotifications += newStats.numberOfNotifications;
    stats.numberOfResendNotifications += newStats.numberOfResendNotifications;
    stats.numberOfRequestedNotifications += newStats.numberOfRequestedNotifications;
    stats.numberOfConfirmations += newStats.numberOfConfirmations;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func update(map: Map.Map<(Principal, Text), State.Stats>, principalId: Principal, eventName: Text, newStats: Types.SharedStats) {
    ignore Map.update<(Principal, Text), State.Stats>(map, pthash, (principalId, eventName), func(key, value) {
      let stats = fallback(value, build);

      merge(stats, newStats);

      return ?stats;
    });
  };
};
