import V0_1_0 "./00-01-00-initial/types";

module {
  public let Current = V0_1_0;

  public type Args = {};

  public type State = {
    #v0_0_0: { #id; #data: () };
    #v0_1_0: { #id; #data: V0_1_0.State };
  };
};