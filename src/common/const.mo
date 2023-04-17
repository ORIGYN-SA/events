module {
  public let RESEND_DELAY = 900_000_000_000:Nat64; // 15 * 60 * 1_000_000_000

  public let RESEND_CHECK_DELAY = 180_000_000_000:Nat64; // 3 * 60 * 1_000_000_000

  public let BROADCAST_RETRY_DELAY = 5_000_000_000:Nat64; // 5 * 1_000_000_000

  public let STATS_TRANSFER_INTERVAL = 120_000_000_000:Nat64; // 2 * 60 * 1_000_000_000

  public let UPDATE_METRICS_INTERVAL = 180_000_000_000:Nat64; // 3 * 60 * 1_000_000_000

  public let CANISTER_DEACTIVATE_THRESHOLD = 1_932_735_283; // 1.8 * 2 ** 30

  public let CANISTER_REACTIVATE_THRESHOLD = 1_503_238_553; // 1.4 * 2 ** 30

  public let CANISTER_CREATE_COST = 100_000_000_000;

  public let CANISTER_TOP_UP_THRESHOLD = 1_000_000_000_000;

  public let CANISTER_TOP_UP_AMOUNT = 5_000_000_000_000;

  public let SUBSCRIBERS_BATCH_SIZE = 10000;

  public let STATS_BATCH_SIZE = 10000;

  public let SYNC_CALLS_LIMIT = 400;

  public let RESEND_ATTEMPTS_LIMIT = 8:Nat8;

  public let EVENT_NAME_LENGTH_LIMIT = 50;

  public let FILTER_LENGTH_LIMIT = 500;

  public let ACTIVE_SUBSCRIPTIONS_LIMIT = 100:Nat8;

  public let SUBSCRIPTIONS_LIMIT = 500;

  public let ACTIVE_PUBLICATIONS_LIMIT = 100:Nat8;

  public let PUBLICATIONS_LIMIT = 500;

  public let PUBLISHER_WHITELIST_LIMIT = 500;

  public let SUBSCRIBER_WHITELIST_LIMIT = 500;

  public let LISTENERS_LIMIT = 100;
};