import Array "mo:base/Array";
import Option "mo:base/Option";
import Types001 "../001-initial/types";
import Types002 "./types";
import MigrationTypes "../types";

module {
  public func upgrade(migrationState: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    let #state001(#data(state)) = migrationState;

    let subscribers = Array.map(state.subscribers, func(subscriber: Types001.Subscriber): Types002.Subscriber {{
      canisterId = subscriber.canisterId;
      createdAt = subscriber.createdAt;
      var stale = subscriber.stale;
      var subscriptions = subscriber.eventNames;
    }});

    let events = Array.map(state.events, func(event: Types001.Event): Types002.Event {
      let eventSubscribers = Array.map(event.subscribers, func(prevSubscriber: Types001.Subscriber): Types002.Subscriber {
        return Option.unwrap(Array.find(subscribers, func(newSubscriber: Types002.Subscriber): Bool {
          return newSubscriber.canisterId == prevSubscriber.canisterId;
        }));
      });

      return {
        id = event.id;
        name = event.name;
        payload = event.payload;
        emitter = event.canisterId;
        createdAt = event.createdAt;
        var nextProcessingTime = event.nextProcessingTime;
        var numberOfAttempts = event.numberOfAttempts;
        var stale = event.stale;
        var subscribers = eventSubscribers;
      }
    });

    return #state002(#data({
      var admins = state.admins;
      var eventId = state.eventId;
      var subscribers = subscribers;
      var events = events;
    }));
  };

  public func downgrade(migrationState: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    let #state002(#data(state)) = migrationState;

    let subscribers = Array.map(state.subscribers, func(subscriber: Types002.Subscriber): Types001.Subscriber {{
      canisterId = subscriber.canisterId;
      createdAt = subscriber.createdAt;
      var firstFailedEventTime = 0;
      var stale = subscriber.stale;
      var eventNames = subscriber.subscriptions;
    }});

    let events = Array.map(state.events, func(event: Types002.Event): Types001.Event {
      let eventSubscribers = Array.map(event.subscribers, func(prevSubscriber: Types002.Subscriber): Types001.Subscriber {
        return Option.unwrap(Array.find(subscribers, func(newSubscriber: Types001.Subscriber): Bool {
          return newSubscriber.canisterId == prevSubscriber.canisterId;
        }));
      });

      return {
        id = event.id;
        name = event.name;
        payload = event.payload;
        canisterId = event.emitter;
        createdAt = event.createdAt;
        var nextProcessingTime = event.nextProcessingTime;
        var numberOfDispatches = 0;
        var numberOfAttempts = event.numberOfAttempts;
        var stale = event.stale;
        var subscribers = eventSubscribers;
      }
    });

    return #state001(#data({
      var admins = state.admins;
      var eventId = state.eventId;
      var subscribers = subscribers;
      var events = events;
    }));
  };
};