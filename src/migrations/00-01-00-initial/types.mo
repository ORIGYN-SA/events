import Candy "mo:candy_0_1_9/types";
import Map "mo:map_4_0_0/Map";
import Set "mo:map_4_0_0/Set";

module {
  public type Subscriber = {
    canisterId: Principal;
    createdAt: Int;
    var stale: Bool;
    var subscriptions: Set.Set<Text>;
  };

  public type Event = {
    id: Nat;
    name: Text;
    payload: Candy.CandyValue;
    emitter: Principal;
    createdAt: Int;
    var nextProcessingTime: Int;
    var numberOfAttempts: Nat;
    var stale: Bool;
    var subscribers: Set.Set<Principal>;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type State = {
    var admins: Set.Set<Principal>;
    var eventId: Nat;
    var subscribers: Map.Map<Principal, Subscriber>;
    var events: Map.Map<Nat, Event>;
  };
};