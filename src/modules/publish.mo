import Candy "mo:candy/types";
import Cascade "./cascade";
import Const "./const";
import Debug "mo:base/Debug";
import Map "mo:map/Map";
import MigrationTypes "../migrations/types";
import Option "mo:base/Option";
import Prim "mo:prim";
import Principal "mo:base/Principal";
import Set "mo:map/Set";
import Subscribe "./subscribe";
import Utils "../utils/misc";

module {
  let State = MigrationTypes.Current;

  let { get = coalesce } = Option;

  let { nat8ToNat64; pthash } = Utils;

  let { nhash; thash; phash; lhash; calcHash } = Map;

  let { time } = Prim;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  let PublicationOptionsSize = 3;

  public type PublicationOptions = [{
    #whitelist: [Principal];
    #whitelistAdd: [Principal];
    #whitelistRemove: [Principal];
  }];

  let RemovePublicationOptionsSize = 1;

  public type RemovePublicationOptions = [{
    #purge;
  }];

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.State, deployer: Principal): {
    broadcast: () -> async ();
    registerPublication: (caller: Principal, eventName: Text, options: PublicationOptions) -> ();
    removePublication: (caller: Principal, eventName: Text, options: RemovePublicationOptions) -> ();
    publish: (caller: Principal, eventName: Text, payload: Candy.CandyValue) -> async ();
  } = object {
    let { removeEventCascade } = Cascade.init(state, deployer);

    let { subscribers; subscriptions; publishers; publications; events } = state;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    func broadcastEvent(event: State.Event): async () {
      if (event.numberOfAttempts < Const.RESEND_ATTEMPTS_LIMIT) {
        let { eventId; eventName; payload; publisherId } = event;

        event.numberOfAttempts +%= 1;
        event.nextResendTime := time() + Const.RESEND_DELAY * 2 ** nat8ToNat64(event.numberOfAttempts -% 1);

        for (subscriberId in Set.keys(event.subscribers)) ignore do ?{
          let subscription = Map.get(subscriptions, pthash, (subscriberId, eventName))!;

          if (subscription.active and not subscription.stopped) {
            let subscriberActor: Subscribe.SubscriberActor = actor(Principal.toText(subscriberId));

            subscriberActor.handleEvent(eventId, publisherId, eventName, payload);
          };
        };
      } else {
        removeEventCascade(event.eventId);
      };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func broadcast(): async () {
      let currentTime = time();

      if (currentTime > state.nextBroadcastTime) {
        state.nextBroadcastTime := currentTime + Const.BROADCAST_DELAY;

        for (event in Map.vals(events)) if (currentTime >= event.nextResendTime) ignore broadcastEvent(event);
      };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func registerPublication(caller: Principal, eventName: Text, options: PublicationOptions) {
      if (eventName.size() > Const.EVENT_NAME_LENGTH_LIMIT) Debug.trap("Event name length limit reached");
      if (options.size() > PublicationOptionsSize) Debug.trap("Invalid number of options");

      let publisher = Map.update<Principal, State.Publisher>(publishers, phash, caller, func(key, value) = coalesce(value, {
        publisherId = caller;
        createdAt = time();
        var activePublications = 0:Nat8;
        publications = Set.new(thash);
      }));

      Set.add(publisher.publications, thash, eventName);

      if (Set.size(publisher.publications) > Const.PUBLICATIONS_LIMIT) Debug.trap("Publications limit reached");

      let publication = Map.update<State.PT, State.Publication>(publications, pthash, (caller, eventName), func(key, value) = coalesce(value, {
        eventName = eventName;
        publisherId = caller;
        var active = false;
        whitelist = Set.new(phash);
      }));

      if (not publication.active) {
        publication.active := true;
        publisher.activePublications +%= 1;

        if (publisher.activePublications > Const.ACTIVE_PUBLICATIONS_LIMIT) Debug.trap("Active publications limit reached");
      };

      let { whitelist } = publication;

      for (option in options.vals()) switch (option) {
        case (#whitelist(principalIds)) {
          Set.clear(publication.whitelist);

          if (principalIds.size() > Const.WHITELIST_LIMIT) Debug.trap("Whitelist option length limit reached");

          for (principalId in principalIds.vals()) Set.add(whitelist, phash, principalId);
        };

        case (#whitelistAdd(principalIds)) {
          if (principalIds.size() > Const.WHITELIST_LIMIT) Debug.trap("WhitelistAdd option length limit reached");

          for (principalId in principalIds.vals()) Set.add(whitelist, phash, principalId);

          if (Set.size(whitelist) > Const.WHITELIST_LIMIT) Debug.trap("Whitelist length limit reached");
        };

        case (#whitelistRemove(principalIds)) {
          if (principalIds.size() > Const.WHITELIST_LIMIT) Debug.trap("WhitelistRemove option length limit reached");

          for (principalId in principalIds.vals()) Set.delete(whitelist, phash, principalId);
        };
      };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func removePublication(caller: Principal, eventName: Text, options: RemovePublicationOptions) {
      if (eventName.size() > Const.EVENT_NAME_LENGTH_LIMIT) Debug.trap("Event name length limit reached");
      if (options.size() > RemovePublicationOptionsSize) Debug.trap("Invalid number of options");

      ignore do ?{
        let publisher = Map.get(publishers, phash, caller)!;
        let publication = Map.get(publications, pthash, (caller, eventName))!;

        if (publication.active) {
          publication.active := false;
          publisher.activePublications -%= 1;
        };

        for (option in options.vals()) switch (option) {
          case (#purge) {
            Set.delete(publisher.publications, thash, eventName);
            Map.delete(publications, pthash, (caller, eventName));
          };
        };
      };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func publish(caller: Principal, eventName: Text, payload: Candy.CandyValue): async () {
      if (eventName.size() > Const.EVENT_NAME_LENGTH_LIMIT) Debug.trap("Event name length limit reached");

      let eventId = state.eventId;
      let eventSubscribers = Set.new(phash);

      registerPublication(caller, eventName, []);

      ignore do ?{
        let publication = Map.get(publications, pthash, (caller, eventName))!;
        let subscriberIds = if (Set.size(publication.whitelist) > 0) Set.keys(publication.whitelist) else Map.keys(subscribers);

        for (subscriberId in subscriberIds) ignore do ?{
          let subscription = Map.get(subscriptions, pthash, (subscriberId, eventName))!;

          if (subscription.active) if (subscription.skipped >= subscription.skip) {
            subscription.skipped := 0;

            Set.add(eventSubscribers, phash, subscriberId);
            Set.add(subscription.events, nhash, eventId);
          } else {
            subscription.skipped += 1;
          };
        };
      };

      if (Set.size(eventSubscribers) > 0) {
        let event: State.Event = {
          eventId = eventId;
          eventName = eventName;
          payload = payload;
          publisherId = caller;
          createdAt = time();
          var nextResendTime = time();
          var numberOfAttempts = 0;
          subscribers = eventSubscribers;
        };

        Map.set(events, nhash, eventId, event);

        state.eventId += 1;

        ignore broadcastEvent(event);
      };
    };
  };
};
