import Migration001 "./001-initial/types";
import Migration002 "./002-one-time-calls/types";

module {
  public let Current = Migration002;

  public type Args = {
    deployer: Principal;
  };

  public type State = {
    #state000: { #id; #data: () };
    #state001: { #id; #data: Migration001.State };
    #state002: { #id; #data: Migration002.State };
  };
};