import Candy "mo:candy/types";
import Const "./const";
import Debug "mo:base/Debug";
import Map "mo:map/Map";
import MigrationTypes "../migrations/types";
import Option "mo:base/Option";
import Prim "mo:prim";
import Principal "mo:base/Principal";
import Set "mo:map/Set";
import Utils "../utils/misc";

module {
  let State = MigrationTypes.Current;

  let { get = coalesce } = Option;

  let { pthash } = Utils;

  let { nhash; thash; phash; lhash } = Map;

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
    registerPublication: (caller: Principal, eventName: Text, options: PublicationOptions) -> ();
    removePublication: (caller: Principal, eventName: Text, options: RemovePublicationOptions) -> ();
    publish: (caller: Principal, eventName: Text, payload: Candy.CandyValue) -> ();
  } = object {
    let { subscribers; subscriptions; publishers; publications; events } = state;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func registerPublication(caller: Principal, eventName: Text, options: PublicationOptions) {
      if (eventName.size() > Const.EVENT_NAME_LENGTH_LIMIT) Debug.trap("Event name length limit reached");
      if (options.size() > PublicationOptionsSize) Debug.trap("Invalid number of options");

      let publisher = Map.update<Principal, State.Publisher>(publishers, phash, caller, func(key, value) = coalesce(value, {
        id = caller;
        createdAt = time();
        var activePublications = 0:Nat8;
        publications = Set.new(thash);
      }));

      Set.add(publisher.publications, thash, eventName);

      if (Set.size(publisher.publications) > Const.PUBLICATIONS_LIMIT) Debug.trap("Publications limit reached");

      let publication = Map.update<State.PubId, State.Publication>(publications, pthash, (caller, eventName), func(key, value) = coalesce(value, {
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

      for (option in options.vals()) switch (option) {
        case (#whitelist(principalIds)) {
          Set.clear(publication.whitelist);

          if (principalIds.size() > Const.WHITELIST_LIMIT) Debug.trap("Whitelist option length limit reached");

          for (principalId in principalIds.vals()) Set.add(publication.whitelist, phash, principalId);
        };

        case (#whitelistAdd(principalIds)) {
          if (principalIds.size() > Const.WHITELIST_LIMIT) Debug.trap("WhitelistAdd option length limit reached");

          for (principalId in principalIds.vals()) Set.add(publication.whitelist, phash, principalId);

          if (Set.size(publication.whitelist) > Const.WHITELIST_LIMIT) Debug.trap("Whitelist length limit reached");
        };

        case (#whitelistRemove(principalIds)) {
          if (principalIds.size() > Const.WHITELIST_LIMIT) Debug.trap("WhitelistRemove option length limit reached");

          for (principalId in principalIds.vals()) Set.delete(publication.whitelist, phash, principalId);
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

    public func publish(caller: Principal, eventName: Text, payload: Candy.CandyValue) {
      if (eventName.size() > Const.EVENT_NAME_LENGTH_LIMIT) Debug.trap("Event name length limit reached");

      let eventSubscribers = Map.new<Principal, Nat8>(phash);

      registerPublication(caller, eventName, []);

      ignore do ?{
        let publication = Map.get(publications, pthash, (caller, eventName))!;
        let subscriberIds = if (Set.size(publication.whitelist) > 0) Set.keys(publication.whitelist) else Map.keys(subscribers);

        for (subscriberId in subscriberIds) ignore do ?{
          let subscription = Map.get(subscriptions, pthash, (subscriberId, eventName))!;

          if (subscription.active) if (subscription.skipped >= subscription.skip) {
            subscription.skipped := 0;

            Map.set(eventSubscribers, phash, subscriberId, 0:Nat8);
            Set.add(subscription.events, nhash, state.eventId);
          } else {
            subscription.skipped += 1;
          };
        };
      };

      if (Map.size(eventSubscribers) > 0) {
        Map.set(events, nhash, state.eventId, {
          id = state.eventId;
          eventName = eventName;
          payload = payload;
          publisherId = caller;
          createdAt = time();
          var nextResendTime = time();
          var numberOfAttempts = 0:Nat8;
          resendRequests = Set.new(phash);
          subscribers = eventSubscribers;
        });

        state.eventId += 1;

        state.nextBroadcastTime := time();
      };
    };
  };
};
