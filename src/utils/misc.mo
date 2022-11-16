import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Prim "mo:prim";
import Map "mo:map/Map";

module {
  let { abs; nat8ToNat; natToNat64; hashBlob; encodeUtf8; blobOfPrincipal; principalOfBlob } = Prim;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func intToNat(int: Int): Nat {
    if (int > 0) abs(int) else 0;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func nat8ToNat64(nat8: Nat8): Nat64 {
    natToNat64(nat8ToNat(nat8));
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func unwrap<T>(value: ?T): T {
    switch (value) { case (?value) value; case (_) Debug.trap("Unwrapping null value") };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func arraySlice<T>(array: [T], from: ?Int, to: ?Int): [T] {
    let size = array.size();

    let sliceFrom = switch (from) {
      case (?from) if (from < 0) intToNat(size + from) else intToNat(from);
      case (_) 0;
    };

    let sliceTo = switch (to) {
      case (?to) if (to < 0) intToNat(size + to) else if (to < size) intToNat(to) else size;
      case (_) size;
    };

    return if (sliceTo > sliceFrom) Array.tabulate<T>(sliceTo - sliceFrom, func(i) { array[sliceFrom + i] }) else [];
  };
};
