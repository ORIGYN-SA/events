import Debug "mo:base/Debug";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Option "mo:base/Option";
import Order "mo:base/Order";
import Result "mo:base/Result";
import Candy "mo:candy/types";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Char "mo:base/Char";
import Int "mo:base/Int";
import Int8 "mo:base/Int8";
import Int16 "mo:base/Int16";
import Int32 "mo:base/Int32";
import Int64 "mo:base/Int64";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Float "mo:base/Float";
import Bool "mo:base/Bool";
import Principal "mo:base/Principal";

module {
  public func arraySlice<T>(arr: [T], from: ?Int, to: ?Int): [T] {
    var index = 0;

    var splitFrom = Option.get(from, 0);
    var splitTo = Option.get(to, arr.size());

    splitFrom := if (splitFrom < 0) arr.size() + splitFrom else splitFrom;
    splitTo := if (splitTo < 0) arr.size() + splitTo else splitTo;

    if (splitTo < splitFrom) splitTo := splitFrom;

    return Array.filter(arr, func(item: T): Bool {
      let include = index >= splitFrom and index < splitTo;

      index += 1;

      return include;
    });
  };
};
