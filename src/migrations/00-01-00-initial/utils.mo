import Map "mo:map_8_0_0_rc_2/Map";
import Prim "mo:prim";

module {
  public let pthash: Map.HashUtils<(Principal, Text)> = (
    func(key) = (Prim.hashBlob(Prim.blobOfPrincipal(key.0)) +% Prim.hashBlob(Prim.encodeUtf8(key.1))) & 0x3fffffff,
    func(a, b) = a.0 == b.0 and a.1 == b.1,
    func() = (Prim.principalOfBlob(""), ""),
  );
};
