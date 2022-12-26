module {
  public let RESEND_DELAY = 900_000_000_000:Nat64; // 15 * 60 * 1_000_000_000

  public let BROADCAST_DELAY = 180_000_000_000:Nat64; // 3 * 60 * 1_000_000_000

  public let STATS_TRANSFER_INTERVAL = 120_000_000_000:Nat64; // 2 * 60 * 1_000_000_000

  public let BROADCAST_BATCH_SIZE = 200:Nat8;

  public let SUBSCRIBERS_BATCH_SIZE = 10000;

  public let STATS_BATCH_SIZE = 10000;

  public let SYNC_CALLS_LIMIT = 200:Nat8;

  public let RESEND_ATTEMPTS_LIMIT = 8:Nat8;

  public let EVENT_NAME_LENGTH_LIMIT = 50;

  public let FILTER_LENGTH_LIMIT = 500;

  public let ACTIVE_SUBSCRIPTIONS_LIMIT = 100:Nat8;

  public let SUBSCRIPTIONS_LIMIT = 500;

  public let ACTIVE_PUBLICATIONS_LIMIT = 100:Nat8;

  public let PUBLICATIONS_LIMIT = 500;

  public let WHITELIST_LIMIT = 500;

  public let LISTENERS_LIMIT = 100;
};
