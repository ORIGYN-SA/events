# Subscribe / emit flow

To subscribe to any event canister should:

1) Call `subscribe(event name)` on Event System canister
2) Have a `handleEvent(event id, canister id, event name, candy payload)` method
3) Call `confirmEventProcessed(event id)` at the end of `handleEvent` method

To unsubscribe from any event canister should:

1) Call `unsubscribe(event name)` on Event System canister

To emit an event canister should:

1) Call `emit(event name, candy payload)` method on Event System canister

# Retry logic

Once event is emitted, Event System will attempt to send it to all of its subscribers. If any of the subscribers fails to receive the event, 
retry logic kicks in. There will be up to 7 retries over 32 hours with increasing delay. Event System determines whether or not an event was 
successfully delivered by handling a `confirmEventProcessed` call.

If any of the event subscribers fails to send confirmation about successful event processing within 64 hours from the first event sending attempt, 
these subscribers, as well as the event itself become **stale**. Later admin can either remove or recover (restart sending/resending logic from the 
beginning) such events/subscribers.

If a subscriber receives the event but forgets/refuses to send confirmation about successful event processing, such cases will be treated the same as
failed events (there will be up to 7 retries - duplicated events in this case, after 64 hours such subscribers will stop receiving events at all).

# Admin interface

- `addSubscription(canister id, event name)`
- `removeSubscription(canister id, event name)`
- `addEvent(canister id, event name, candy payload)`
- `fetchSubscribers(filters)`
- `fetchEvents(filters)`
- `removeStaleSubscribers()`
- `removeStaleEvents()`
- `recoverStaleSubscribers()`
- `recoverStaleEvents()`
- `removeSubscriber(canister id)`
- `removeEvent(event id)`
- `recoverSubscriber(canister id)`
- `recoverEvent(event id)`

# Misc

- Event priorities are not included to the first release
- Event permissions are not included to the first release
