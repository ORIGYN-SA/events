# Subscriber Interface

```ts
func handleEvent(eventId: Nat, publisherId: Principal, eventName: Text, payload: Candy.CandyValue)
```
Any subscriber should have this method to be able to receive events. The system will not wait until a subscriber finishes processing an event. Therefore `confirmEventProcessed` method should be called at the end of a `handleEvent` method to notify the system about successful event processing. If `confirmEventProcessed` is not called, an event will be treated as failed, retry logic will kick in.

# Droute Interface

## Publish

```ts
func registerPublication(eventName: Text, options: Publish.PublicationOptions): async ()
```
Registers a new publication or updates an existing one. Activates inactive publications (those that were removed without a `purge` option). It is not required to register a new publication before starting to publish a new event. When the first event of its type is published, a new publication is automatically registered. This method is useful for applying options to your publication.

Options (variants array)

- `#subscriberWhitelist`: [Principal]

Specify canisters that will be able to receive your publication's events. Replaces the previous subscriberWhitelist. By default, everyone can receive events (subscriberWhitelist is empty).

- `#subscriberWhitelistAdd`: [Principal]

Add canisters to the subscriberWhitelist.

- `#subscriberWhitelistRemove`: [Principal]

Remove canisters from the subscriberWhitelist.

---

```ts
func removePublication(eventName: Text, options: Publish.RemovePublicationOptions): async ()
```
Marks a publication as inactive. Publication data (including statistics) stays in the system. Inactive publication should be reactivated before continuing to publish its events. Useful for clearing space for new publications when the limit of active publications is reached.

Options (variants array)

- `#purge`

Completely removes publication together will all statistics. Useful for clearing space for new publications when the overall limit of publications is reached.

---

```ts
func publish(eventName: Text, payload: Candy.CandyValue): async ()
```
Publishes a new event. Tries to register a new publication with the corresponding `eventName` if it does not exist. The system will start broadcasting this event to all of its subscribers. If any of the subscribers fail to receive the event, retry logic kicks in. There will be up to 7 retries over 64 hours with increasing delay. The system will stop trying to deliver events to non-responding subscribers after 64 hours.

---

## Subscribe

```ts
func registerSubscriber(options: Subscribe.SubscriberOptions): async ()
```
Registers a new subscriber or updates an existing one. It is not required to register a new subscriber before subscribing to events. On the first subscription, a new subscriber will be registered automatically. This method is useful for applying subscriber options.

Options (variants array)

- `#listeners`: [Principal]

Specify canisters for the system to round-robin events to. These canisters should confirm they want to receive events for that subscriber either before or after they were added to the listeners list by calling `confirmListener`. Replaces the previous listeners list. By default subscriber's canister is the only listener.

- `#listenersAdd`: [Principal]

Add canisters to the listeners list.

- `#listenersRemove`: [Principal]

Remove canisters from the listeners list.

---

```ts
func subscribe(eventName: Text, options: Subscribe.SubscriptionOptions): async ()
```
Registers a new subscription or updates an existing one, listening for all events with the name `eventName`. Tries to register a new subscriber with the corresponding `eventName` if it does not exist.

Options (variants array)

- `#stopped`: Bool

Marks a subscription as stopped. The system will avoid sending event notifications to stopped subscriptions. Events will still be saved in the system for up to retry-logic-period (64 hours), making it possible to request events missed during the stopped subscription period using `requestMissedEvents` method. Also, the system will automatically try to resend such missed events when the subscription becomes active again under retry logic. Useful when you want to make further preparations before you start receiving events but you don't want to miss events that came during the preparation period. Defaults to false.

- `#skip`: Nat8

Skip a number of subsequent events with the same `eventName` before receiving one. Useful for frequent events whose content (payload) matters less than the fact of receiving such event. Defaults to 0.

- `#filter`: ?Text

Determines whether event notification should be pushed based on the event payload. Should return a boolean, otherwise, all events will pass (same as no filter present). See [Candy Path](https://github.com/ZhenyaUsenko/motoko-candy-utils) for filter syntax. Defaults to null.

---

```ts
func unsubscribe(eventName: Text, options: Subscribe.UnsubscribeOptions): async ()
```
Marks a subscription as inactive. Subscription data (including statistics) stays in the system. The system will not push event notifications for inactive subscriptions.

Options (variants array)

- `#purge`

Completely removes a subscription together will all statistics. Useful for clearing space for new subscriptions when the overall limit of subscriptions is reached.

---

```ts
func requestMissedEvents(eventName: Text, options: Subscribe.MissedEventOptions): async ()
```
Request events that were missed for any reason (e.g. subscription was stopped, subscriber's canister was out of cycles, etc.). Only those events that fall under retry logic are requestable with this method (64 hours max).

Options (variants array)

- `#from`: Nat64

Event creation time should be greater than or equal to this time.

- `#to`: Nat64

Event creation time should be less than or equal to this time.

---

```ts
func confirmListener(subscriberId: Principal, allow: Bool): async ()
```
Allows a canister to confirm that it wants to receive events for a subscriber `subscriberId` (be its listener) or cancel confirmation (when `allow` is false). Subscriber should also add this canister to its listeners list either before or after the confirmation. One canister can be a listener of only one subscriber. Subscriber's main canister (the one that calls `subscribe`) should not call this method.

---

```ts
func confirmEventProcessed(eventId: Nat): async ()
```
Subscribers should call this method at the end of their event handler method (`handleEvent`) to confirm an event was successfully processed. If this method is not called, an event will be treated as failed, retry logic will kick in. In case of a successfully processed event without confirmation, retries will mean duplicated events.

---

## Stats

```ts
func getPublicationStats(options: Stats.StatsOptions): async Stats.Stats
```
Return publication stats. By default returns stat sums of all publications of a publisher. Allows filtering publications that will be aggregated into the sum with options.

Options (variants array)

- `#active`: Bool

Aggregate only active/inactive publications.

- `#eventNames`: [Text]

Aggregate only those publications which have their names present inside `eventNames` array. This option also allows fetching single publication stats.

Stats object type

- `numberOfEvents`: Nat64

A total number of events published.

- `numberOfNotifications`: Nat64

A total number of event notifications (facts of sending an event to a subscriber).

- `numberOfResendNotifications`: Nat64

A total number of event notifications excluding every first notification attempt to every subscriber of any event.

- `numberOfRequestedNotifications`: Nat64

A total number of notifications sent as a result of `requestMissedEvents` method call of any subscriber.

- `numberOfConfirmations`: Nat64

A total number of times any subscriber successfully confirmed event processing with `confirmEventProcessed` method (was not a duplicated confirmation, event existed and was awaiting confirmation of a subscriber).

---

```ts
func getSubscriptionStats(options: Stats.StatsOptions): async Stats.Stats
```
Return subscription stats. By default returns stat sums of all subscriptions of a subscriber. Allows filtering subscriptions that will be aggregated into the sum with options.

Options

#active: Bool

Aggregate only active/inactive subscriptions.

#eventNames: [Text]

Aggregate only those subscriptions which have their names present inside `eventNames` array. This option also allows fetching single subscription stats.

Stats object type

- `numberOfEvents`: Nat64

A total number of events about to be sent to a subscriber, after applying all possible filters (like `#skip` and `#filter` options of a `subscribe` method). This stat is incremented every time an event is published, before the fact of event notification.

- `numberOfNotifications`: Nat64

A total number of event notifications. If subscription is `active`, not `stopped` and subscriber has `listeners` the following will be true (`numberOfNotifications` - `numberOfResendNotifications` - `numberOfRequestedNotifications` == `numberOfEvents`).

- `numberOfResendNotifications`: Nat64

A total number of event notifications excluding every first notification attempt of any event.

- `numberOfRequestedNotifications`: Nat64

A total number of notifications sent as a result of calling `requestMissedEvents` method.

- `numberOfConfirmations`: Nat64

A total number of times a subscriber successfully confirmed event processing with `confirmEventProcessed` method (was not a duplicated confirmation, event existed and was awaiting confirmation of a subscriber).

