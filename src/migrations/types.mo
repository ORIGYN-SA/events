import V0_1_0 "./00-01-00-initial/types";
import V0_2_0 "./00-02-00-publisher-entities/types";
import V0_3_0 "./00-03-00-multiple-listeners/types";
import V0_4_0 "./00-04-00-map-8/types";

module {
  public let Current = V0_4_0;

  public type Args = {};

  public type State = {
    #v0_0_0: { #id; #data: () };
    #v0_1_0: { #id; #data: V0_1_0.State };
    #v0_2_0: { #id; #data: V0_2_0.State };
    #v0_3_0: { #id; #data: V0_3_0.State };
    #v0_4_0: { #id; #data: V0_4_0.State };
  };
};