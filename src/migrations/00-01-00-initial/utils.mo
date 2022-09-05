import Map "mo:map_8_0_0_alpha_5/Map";
import Prim "mo:prim";

module {
  let { hashBlob; encodeUtf8; blobOfPrincipal; principalOfBlob } = Prim;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func hashPrincipalText(key: (Principal, Text)): Nat32 {
    (hashBlob(blobOfPrincipal(key.0)) +% hashBlob(encodeUtf8(key.1))) & 0x3fffffff;
  };

  public let pthash: Map.HashUtils<(Principal, Text)> = (
    hashPrincipalText,
    func(a, b) { a.0 == b.0 and encodeUtf8(a.1) == encodeUtf8(b.1) },
    func() { (principalOfBlob(""), "") },
  );
};
