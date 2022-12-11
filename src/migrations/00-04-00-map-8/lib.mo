import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Map "mo:map_8_0_0_rc_2/Map";
import Set "mo:map_8_0_0_rc_2/Set";
import MigrationTypes "../types";
import PrevMap "mo:map_8_0_0_alpha_5/Map";
import PrevSet "mo:map_8_0_0_alpha_5/Set";
import PrevTypes "../00-03-00-multiple-listeners/types";
import Types "./types";

module {
  public func upgrade(migrationState: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    let state = switch (migrationState) { case (#v0_3_0(#data(state))) state; case (_) Debug.trap("Unexpected migration state") };

    let events = Map.fromIterMap<Nat, Types.Event, (Nat, PrevTypes.Event)>(
      PrevMap.entries(state.events),
      Map.nhash,
      func(key, event) = ?(key, {
        id = event.id;
        eventName = event.eventName;
        publisherId = event.publisherId;
        payload = event.payload;
        createdAt = event.nextBroadcastTime;
        var nextBroadcastTime = event.nextBroadcastTime;
        var numberOfAttempts = event.numberOfAttempts;
        resendRequests = Set.fromIter(PrevSet.keys(event.resendRequests), Map.phash);
        subscribers = Map.fromIter<Principal, Nat8>(PrevMap.entries(event.subscribers), Map.phash);
      }),
    );

    let publishers = Map.fromIterMap<Principal, Types.Publisher, (Principal, PrevTypes.Publisher)>(
      PrevMap.entries(state.publishers),
      Map.phash,
      func(key, publisher) = ?(key, {
        id = publisher.id;
        createdAt = publisher.createdAt;
        var activePublications = publisher.activePublications;
        publications = Set.fromIter(PrevSet.keys(publisher.publications), Map.thash);
      }),
    );

    let publications = Map.fromIterMap<Text, Types.PublicationGroup, (Text, PrevTypes.PublicationGroup)>(
      PrevMap.entries(state.publications),
      Map.thash,
      func(key, publicationGroup) = ?(key, Map.fromIterMap<Principal, Types.Publication, (Principal, PrevTypes.Publication)>(
        PrevMap.entries(publicationGroup),
        Map.phash,
        func(key, publication) = ?(key, {
          eventName = publication.eventName;
          publisherId = publication.publisherId;
          createdAt = publication.createdAt;
          var active = publication.active;
          var numberOfEvents = publication.numberOfEvents;
          var numberOfNotifications = publication.numberOfNotifications;
          var numberOfResendNotifications = publication.numberOfResendNotifications;
          var numberOfRequestedNotifications = publication.numberOfRequestedNotifications;
          var numberOfConfirmations = publication.numberOfConfirmations;
          whitelist = Set.fromIter(PrevSet.keys(publication.whitelist), Map.phash);
        }),
      )),
    );

    let subscribers = Map.fromIterMap<Principal, Types.Subscriber, (Principal, PrevTypes.Subscriber)>(
      PrevMap.entries(state.subscribers),
      Map.phash,
      func(key, subscriber) = ?(key, {
        id = subscriber.id;
        createdAt = subscriber.createdAt;
        var activeSubscriptions = subscriber.activeSubscriptions;
        listeners = Set.fromIter(PrevSet.keys(subscriber.listeners), Map.phash);
        confirmedListeners = Set.fromIter(PrevSet.keys(subscriber.confirmedListeners), Map.phash);
        subscriptions = Set.fromIter(PrevSet.keys(subscriber.subscriptions), Map.thash);
      }),
    );

    let subscriptions = Map.fromIterMap<Text, Types.SubscriptionGroup, (Text, PrevTypes.SubscriptionGroup)>(
      PrevMap.entries(state.subscriptions),
      Map.thash,
      func(key, subscriptionGroup) = ?(key, Map.fromIterMap<Principal, Types.Subscription, (Principal, PrevTypes.Subscription)>(
        PrevMap.entries(subscriptionGroup),
        Map.phash,
        func(key, subscription) = ?(key, {
          eventName = subscription.eventName;
          subscriberId = subscription.subscriberId;
          createdAt = subscription.createdAt;
          var skip = subscription.skip;
          var skipped = subscription.skipped;
          var active = subscription.active;
          var stopped = subscription.stopped;
          var filter = subscription.filter;
          var filterPath = subscription.filterPath;
          var numberOfEvents = subscription.numberOfEvents;
          var numberOfNotifications = subscription.numberOfNotifications;
          var numberOfResendNotifications = subscription.numberOfResendNotifications;
          var numberOfRequestedNotifications = subscription.numberOfRequestedNotifications;
          var numberOfConfirmations = subscription.numberOfConfirmations;
          events = Set.fromIter(PrevSet.keys(subscription.events), Map.nhash);
        }),
      )),
    );

    return #v0_4_0(#data({
      var eventId = state.eventId;
      var broadcastActive = state.broadcastActive;
      var nextBroadcastTime = state.nextBroadcastTime;
      admins = Set.fromIter(PrevSet.keys(state.admins), Map.phash);
      publishers = publishers;
      publications = publications;
      subscribers = subscribers;
      subscriptions = subscriptions;
      confirmedListeners = Map.fromIter(PrevMap.entries(state.confirmedListeners), Map.phash);
      events = events;
    }));
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func downgrade(migrationState: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    let state = switch (migrationState) { case (#v0_4_0(#data(state))) state; case (_) Debug.trap("Unexpected migration state") };

    let events = PrevMap.fromIter<Nat, PrevTypes.Event>(
      Iter.map<(Nat, Types.Event), (Nat, PrevTypes.Event)>(
        Map.entries(state.events),
        func(key, event) = (key, {
          id = event.id;
          eventName = event.eventName;
          publisherId = event.publisherId;
          payload = event.payload;
          createdAt = event.nextBroadcastTime;
          var nextBroadcastTime = event.nextBroadcastTime;
          var numberOfAttempts = event.numberOfAttempts;
          resendRequests = PrevSet.fromIter(Set.keys(event.resendRequests), PrevMap.phash);
          subscribers = PrevMap.fromIter<Principal, Nat8>(Map.entries(event.subscribers), PrevMap.phash);
        }),
      ),
      PrevMap.nhash,
    );

    let publishers = PrevMap.fromIter<Principal, PrevTypes.Publisher>(
      Iter.map<(Principal, Types.Publisher), (Principal, PrevTypes.Publisher)>(
        Map.entries(state.publishers),
        func(key, publisher) = (key, {
          id = publisher.id;
          createdAt = publisher.createdAt;
          var activePublications = publisher.activePublications;
          publications = PrevSet.fromIter(Set.keys(publisher.publications), PrevMap.thash);
        }),
      ),
      PrevMap.phash,
    );

    let publications = PrevMap.fromIter<Text, PrevTypes.PublicationGroup>(
      Iter.map<(Text, Types.PublicationGroup), (Text, PrevTypes.PublicationGroup)>(
        Map.entries(state.publications),
        func(key, publicationGroup) = (key, PrevMap.fromIter<Principal, PrevTypes.Publication>(
          Iter.map<(Principal, Types.Publication), (Principal, PrevTypes.Publication)>(
            Map.entries(publicationGroup),
              func(key, publication) = (key, {
              eventName = publication.eventName;
              publisherId = publication.publisherId;
              createdAt = publication.createdAt;
              var active = publication.active;
              var numberOfEvents = publication.numberOfEvents;
              var numberOfNotifications = publication.numberOfNotifications;
              var numberOfResendNotifications = publication.numberOfResendNotifications;
              var numberOfRequestedNotifications = publication.numberOfRequestedNotifications;
              var numberOfConfirmations = publication.numberOfConfirmations;
              whitelist = PrevSet.fromIter(Set.keys(publication.whitelist), PrevMap.phash);
            }),
          ),
          PrevMap.phash,
        )),
      ),
      PrevMap.thash,
    );

    let subscribers = PrevMap.fromIter<Principal, PrevTypes.Subscriber>(
      Iter.map<(Principal, Types.Subscriber), (Principal, PrevTypes.Subscriber)>(
        Map.entries(state.subscribers),
        func(key, subscriber) = (key, {
          id = subscriber.id;
          createdAt = subscriber.createdAt;
          var activeSubscriptions = subscriber.activeSubscriptions;
          listeners = PrevSet.fromIter(Set.keys(subscriber.listeners), PrevMap.phash);
          confirmedListeners = PrevSet.fromIter(Set.keys(subscriber.confirmedListeners), PrevMap.phash);
          subscriptions = PrevSet.fromIter(Set.keys(subscriber.subscriptions), PrevMap.thash);
        }),
      ),
      PrevMap.phash,
    );

    let subscriptions = PrevMap.fromIter<Text, PrevTypes.SubscriptionGroup>(
      Iter.map<(Text, Types.SubscriptionGroup), (Text, PrevTypes.SubscriptionGroup)>(
        Map.entries(state.subscriptions),
        func(key, subscriptionGroup) = (key, PrevMap.fromIter<Principal, PrevTypes.Subscription>(
          Iter.map<(Principal, Types.Subscription), (Principal, PrevTypes.Subscription)>(
            Map.entries(subscriptionGroup),
            func(key, subscription) = (key, {
              eventName = subscription.eventName;
              subscriberId = subscription.subscriberId;
              createdAt = subscription.createdAt;
              var skip = subscription.skip;
              var skipped = subscription.skipped;
              var active = subscription.active;
              var stopped = subscription.stopped;
              var filter = subscription.filter;
              var filterPath = subscription.filterPath;
              var numberOfEvents = subscription.numberOfEvents;
              var numberOfNotifications = subscription.numberOfNotifications;
              var numberOfResendNotifications = subscription.numberOfResendNotifications;
              var numberOfRequestedNotifications = subscription.numberOfRequestedNotifications;
              var numberOfConfirmations = subscription.numberOfConfirmations;
              events = PrevSet.fromIter(Set.keys(subscription.events), PrevMap.nhash);
            }),
          ),
          PrevMap.phash,
        )),
      ),
      PrevMap.thash,
    );

    return #v0_3_0(#data({
      var eventId = state.eventId;
      var broadcastActive = state.broadcastActive;
      var nextBroadcastTime = state.nextBroadcastTime;
      admins = PrevSet.fromIter(Set.keys(state.admins), PrevMap.phash);
      publishers = publishers;
      publications = publications;
      subscribers = subscribers;
      subscriptions = subscriptions;
      confirmedListeners = PrevMap.fromIter(Map.entries(state.confirmedListeners), PrevMap.phash);
      events = events;
    }));
  };
};
