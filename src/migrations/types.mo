import Migration001 "./001-initial/types";

module {
  public let Current = Migration001;

  public type Args = {
    deployer: Principal;
  };

  public type State = {
    #state000: { #id; #data: () };
    #state001: { #id; #data: Migration001.State };
  };
};