import Debug "mo:base/Debug";
import Error "mo:base/Error";
import { setTimer } "mo:prim";

module {
  public func setBlockingTimer(delay: Nat64, handler: () -> async* ()): Nat {
    var handlerActive = false;

    return setTimer(delay, true, func(): async () {
      if (not handlerActive) try {
        handlerActive := true;

        await async {
          await* handler();

          handlerActive := false;
        };
      } catch (err) {
        Debug.print(Error.message(err));

        handlerActive := false;
      };
    });
  };
};
