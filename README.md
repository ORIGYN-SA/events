# Subscribe / emit flow

To subscribe to any event canister should:

1) Call `subscribe(event name)` on Event System canister
2) Have `handleEvent(canister id, event name, candy payload)` method

To unsubscribe from any event canister should:

1) Call `unsubscribe(event name)` on Event System canister

To emit event canister should:

1) Call `emit(event name, candy payload)` method on Event System canister

# Retry logic

Once event is emitted, Event System will attempt to send it to all of its subscribers. If any of the subscribers fails to receive the event, 
retry logic kicks in. There will be up to 10 retries over 1 day with increasing delay. 

If the event is still not delivered to all its subscribers after 10 retries, event becomes **stale**. Later admin can either remove or 
recover (restart sending/resending logic from the beginning) such events.

If a subscriber fails to receive any event for 1 week, subscriber itself becomes **stale**. Event System will stop trying to send events to such 
subscribers. Later admin can either remove or recover them.

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
- `removeEvent(id)`
- `recoverSubscriber(canister id)`
- `recoverEvent(id, event name)`

# Misc

- Event priorities are not included to the first release
- Event permissions are not included to the first release
