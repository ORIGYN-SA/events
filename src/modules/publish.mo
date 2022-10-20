import Candy "mo:candy/types";
import CandyUtils "mo:candy_utils/CandyUtils";
import Const "./const";
import Debug "mo:base/Debug";
import Map "mo:map/Map";
import MigrationTypes "../migrations/types";
import Option "mo:base/Option";
import Prim "mo:prim";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Set "mo:map/Set";

module {
  let State = MigrationTypes.Current;

  let { get = coalesce } = Option;

  let { get } = CandyUtils;

  let { nhash; thash; phash; lhash } = Map;

  let { time } = Prim;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  let PublicationOptionsSize = 4;

  public type PublicationOptions = [{
    #whitelist: [Principal];
    #whitelistAdd: [Principal];
    #whitelistRemove: [Principal];
    #confirm: Principal;
  }];

  let RemovePublicationOptionsSize = 1;

  public type PublishingActor = actor{
    registration_response_droute : (Result.Result<State.PublicationStable, Text>) -> ();
  };

  public type RemovePublicationOptions = [{
    #purge;
  }];

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.State, deployer: Principal): {
    registerPublication: (caller: Principal, eventName: Text, options: PublicationOptions) -> State.Publication;
    removePublication: (caller: Principal, eventName: Text, options: RemovePublicationOptions) -> ();
    publish: (caller: Principal, eventName: Text, payload: Candy.CandyValue) -> ();
  } = object {
    let { publishers; publications; subscribers; subscriptions; events } = state;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func registerPublication(caller: Principal, eventName: Text, options: PublicationOptions): State.Publication {
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

      let publicationGroup = Map.update<Text, State.PublicationGroup>(publications, thash, eventName, func(key, value) {
        return coalesce<State.PublicationGroup>(value, Map.new(phash));
      });

      let publication = Map.update<Principal, State.Publication>(publicationGroup, phash, caller, func(key, value) = coalesce(value, {
        eventName = eventName;
        publisherId = caller;
        createdAt = time();
        var active = false;
        var numberOfEvents = 0:Nat64;
        var numberOfNotifications = 0:Nat64;
        var numberOfResendNotifications = 0:Nat64;
        var numberOfRequestedNotifications = 0:Nat64;
        var numberOfConfirmations = 0:Nat64;
        whitelist = Set.new(phash);
      }));

      if (not publication.active) {
        publication.active := true;
        publisher.activePublications +%= 1;

        if (publisher.activePublications > Const.ACTIVE_PUBLICATIONS_LIMIT) Debug.trap("Active publications limit reached");
      };

      for (option in options.vals()) switch (option) {
        case (#whitelist(principalIds)) {
          if (principalIds.size() > Const.WHITELIST_LIMIT) Debug.trap("Whitelist option length limit reached");

          Set.clear(publication.whitelist);

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
        case(_){}
      };

      return publication;
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func removePublication(caller: Principal, eventName: Text, options: RemovePublicationOptions) {
      if (eventName.size() > Const.EVENT_NAME_LENGTH_LIMIT) Debug.trap("Event name length limit reached");
      if (options.size() > RemovePublicationOptionsSize) Debug.trap("Invalid number of options");

      ignore do ?{
        let publisher = Map.get(publishers, phash, caller)!;
        let publicationGroup = Map.get(publications, thash, eventName)!;
        let publication = Map.get(publicationGroup, phash, caller)!;

        if (publication.active) {
          publication.active := false;
          publisher.activePublications -%= 1;
        };

        for (option in options.vals()) switch (option) {
          case (#purge) {
            Set.delete(publisher.publications, thash, eventName);
            Map.delete(publicationGroup, phash, caller);

            if (Map.size(publicationGroup) == 0) Map.delete(publications, thash, eventName);
          };
        };
      };
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func publish(caller: Principal, eventName: Text, payload: Candy.CandyValue) {
      if (eventName.size() > Const.EVENT_NAME_LENGTH_LIMIT) Debug.trap("Event name length limit reached");

      ignore do ?{
        let publication = registerPublication(caller, eventName, []);
        let subscriptionGroup = Map.get(subscriptions, thash, eventName)!;
        let eventSubscribers = Map.new<Principal, Nat8>(phash);
        let subscriberIdsIter = if (Set.size(publication.whitelist) > 0) Set.keys(publication.whitelist) else Map.keys(subscriptionGroup);

        publication.numberOfEvents +%= 1;

        for (subscriberId in subscriberIdsIter) ignore do ?{
          let subscription = Map.get(subscriptionGroup, phash, subscriberId)!;

          if (subscription.active) {
            let filterPassed = switch (subscription.filterPath) {
              case (?filterPath) switch (get(payload, filterPath)) { case (#Bool(bool)) bool; case (_) true };
              case (_) true;
            };

            if (filterPassed) {
              if (subscription.skipped >= subscription.skip) {
                subscription.skipped := 0;

                Map.set(eventSubscribers, phash, subscriberId, 0:Nat8);
                Set.add(subscription.events, nhash, state.eventId);

                subscription.numberOfEvents +%= 1;
              } else {
                subscription.skipped +%= 1;
              };
            };
          };
        };

        if (Map.size(eventSubscribers) > 0) {
          Map.set(events, nhash, state.eventId, {
            id = state.eventId;
            eventName = eventName;
            publisherId = caller;
            payload = payload;
            createdAt = time();
            var nextBroadcastTime = time();
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
};
