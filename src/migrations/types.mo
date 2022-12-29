import V0_1_0 "./00-01-00-initial/types";
import Principal "mo:base/Principal";

module {
  public let Types = V0_1_0;

  public let State = V0_1_0.State;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type Args = {
    mainId: ?Principal;
    publishersIndexId: ?Principal;
    subscribersIndexId: ?Principal;
    broadcastIds: [Principal];
    publishersStoreIds: [Principal];
    subscribersStoreIds: [Principal];
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type StateList = {
    #v0_0_0: { #id; #data: { #Broadcast; #Main; #PublishersIndex; #PublishersStore; #SubscribersIndex; #SubscribersStore } };
    #v0_1_0: { #id; #data: V0_1_0.State.State };
  };
};
