import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Map "mo:map/Map";
import Stats "../../../common/stats";
import { nhash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type TransferStats = (Principal, Text, Types.SharedStats);

  public type ConsumedStats = (Principal, Text);

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func init(state: State.PublishersStoreState, deployer: Principal): {
    consumePublicationStats: (caller: Principal, TransferStats: [TransferStats]) -> [ConsumedStats];
  } = object {
    let { canisters; publications } = state;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func consumePublicationStats(caller: Principal, TransferStats: [TransferStats]): [ConsumedStats] {
      if (not Map.has(canisters, phash, caller)) Debug.trap(Errors.PERMISSION_DENIED);

      let consumedStats = Buffer.Buffer<ConsumedStats>(0);

      for ((publisherId, eventName, stats) in TransferStats.vals()) ignore do ?{
        let publicationGroup = Map.get(publications, thash, eventName)!;
        let publication = Map.get(publicationGroup, phash, publisherId)!;

        Stats.merge(publication.stats, stats);

        consumedStats.add(publisherId, eventName);
      };

      return Buffer.toArray(consumedStats);
    };
  };
};
