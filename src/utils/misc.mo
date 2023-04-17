import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Prim "mo:prim";
import Map "mo:map/Map";

module {
  public func intToNat(int: Int): Nat {
    if (int > 0) Prim.abs(int) else 0;
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func nat8ToNat64(nat8: Nat8): Nat64 {
    Prim.natToNat64(Prim.nat8ToNat(nat8));
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func unwrap<T>(value: ?T): T {
    switch (value) { case (?value) value; case (_) Debug.trap("Unwrapping null value") };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func takeChain<T>(value1: ?T, value2: ?T, message: Text): T {
    switch (value1) {
      case (?value1) value1;
      case (_) switch (value2) { case (?value2) value2; case (_) Debug.trap(message) };
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func fallback<T>(value: ?T, getDefault: () -> T): T {
    switch (value) { case (?value) value; case (_) getDefault() };
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

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public let pthash: Map.HashUtils<(Principal, Text)> = (
    func(key) = (Prim.hashBlob(Prim.blobOfPrincipal(key.0)) +% Prim.hashBlob(Prim.encodeUtf8(key.1))) & 0x3fffffff,
    func(a, b) = a.0 == b.0 and a.1 == b.1,
    func() = (Prim.principalOfBlob(""), ""),
  );
};
