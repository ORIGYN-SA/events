import Candy "mo:candy/types";
import Time "mo:base/Time";

module {
  public type Subscriber = {
    canisterId: Principal;
    createdAt: Time.Time;
    var stale: Bool;
    var subscriptions: [Text];
  };

  public type Event = {
    id: Nat;
    name: Text;
    payload: Candy.CandyValue;
    emitter: Principal;
    createdAt: Time.Time;
    var nextProcessingTime: Time.Time;
    var numberOfAttempts: Nat;
    var stale: Bool;
    var subscribers: [Subscriber];
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type State = {
    var admins: [Principal];
    var eventId: Nat;
    var subscribers: [Subscriber];
    var events: [Event];
  };
};