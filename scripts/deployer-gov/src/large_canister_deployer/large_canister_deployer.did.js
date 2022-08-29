export const idlFactory = ({ IDL }) => {
  const Canister_settings = IDL.Record({
    'freezing_threshold' : IDL.Opt(IDL.Nat),
    'controllers' : IDL.Opt(IDL.Vec(IDL.Principal)),
    'memory_allocation' : IDL.Opt(IDL.Nat),
    'compute_allocation' : IDL.Opt(IDL.Nat),
  });
  const LargeDeployer = IDL.Service({
    'appendWasm' : IDL.Func([IDL.Vec(IDL.Nat8)], [IDL.Nat], []),
    'call_raw' : IDL.Func(
        [IDL.Principal, IDL.Text, IDL.Vec(IDL.Nat8)],
        [IDL.Vec(IDL.Nat8)],
        [],
    ),
    'deleteWasm' : IDL.Func([IDL.Principal], [], ['oneway']),
    'deployWasm' : IDL.Func(
        [
          IDL.Variant({
            'reinstall' : IDL.Null,
            'upgrade' : IDL.Null,
            'install' : IDL.Null,
          }),
          Canister_settings,
          IDL.Principal,
          IDL.Vec(IDL.Nat8),
        ],
        [IDL.Principal],
        [],
      ),
    'getWasmHash' : IDL.Func([], [IDL.Vec(IDL.Nat8)], []),
    'reset' : IDL.Func([], [], []),
    'updateDeployer' : IDL.Func([IDL.Principal], [], ['oneway']),
    'wallet_receive' : IDL.Func(
        [],
        [IDL.Record({ 'accepted' : IDL.Nat64 })],
        [],
      ),
  });
  return LargeDeployer;
};
export const init = ({ IDL }) => { return []; };
