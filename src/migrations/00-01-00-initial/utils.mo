import Debug "mo:base/Debug";
import Map "mo:map_8_0_0_rc_2/Map";
import Prim "mo:prim";

module {
  public func take<T>(value: ?T, message: Text): T {
    switch (value) { case (?value) value; case (_) Debug.trap(message) };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public let pthash: Map.HashUtils<(Principal, Text)> = (
    func(key) = (Prim.hashBlob(Prim.blobOfPrincipal(key.0)) +% Prim.hashBlob(Prim.encodeUtf8(key.1))) & 0x3fffffff,
    func(a, b) = a.0 == b.0 and a.1 == b.1,
    func() = (Prim.principalOfBlob(""), ""),
  );
};
