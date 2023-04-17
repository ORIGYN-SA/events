import Debug "mo:base/Debug";
import Errors "../../../common/errors";
import Set "mo:map/Set";
import { n32hash; n64hash; thash; phash } "mo:map/Map";
import { Types; State } "../../../migrations/types";

module {
  public type GetAdminsResponse = [Principal];

  public type GetAdminsParams = ();

  public type GetAdminsFullParams = (caller: Principal, state: State.MainState, params: GetAdminsParams);

  public func getAdmins((caller, state, ()): GetAdminsFullParams): GetAdminsResponse {
    if (not Set.has(state.admins, phash, caller)) Debug.trap(Errors.PERMISSION_DENIED);

    return Set.toArray(state.admins);
  };
  
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type AddAdminResponse = ();

  public type AddAdminParams = (adminId: Principal);

  public type AddAdminFullParams = (caller: Principal, state: State.MainState, params: AddAdminParams);

  public func addAdmin((caller, state, (adminId)): AddAdminFullParams): AddAdminResponse {
    if (not Set.has(state.admins, phash, caller)) Debug.trap(Errors.PERMISSION_DENIED);

    Set.add(state.admins, phash, adminId);
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type RemoveAdminResponse = ();

  public type RemoveAdminParams = (adminId: Principal);

  public type RemoveAdminFullParams = (caller: Principal, state: State.MainState, params: RemoveAdminParams);

  public func removeAdmin((caller, state, (adminId)): RemoveAdminFullParams): RemoveAdminResponse {
    if (not Set.has(state.admins, phash, caller)) Debug.trap(Errors.PERMISSION_DENIED);

    Set.delete(state.admins, phash, adminId);

    if (Set.empty(state.admins)) Debug.trap(Errors.EMPTY_ADMINS_LIST);
  };
};
