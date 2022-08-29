import type { Principal } from '@dfinity/principal';
export interface Canister_settings {
  'freezing_threshold' : [] | [bigint],
  'controllers' : [] | [Array<Principal>],
  'memory_allocation' : [] | [bigint],
  'compute_allocation' : [] | [bigint],
}
export interface LargeDeployer {
  'appendWasm' : (arg_0: Array<number>) => Promise<bigint>,
  'call_raw' : (
      arg_0: Principal,
      arg_1: string,
      arg_2: Array<number>,
  ) => Promise<Array<number>>,
  'deleteWasm' : (arg_0: Principal) => Promise<undefined>,
  'deployWasm' : (
      arg_0: { 'reinstall' : null } |
        { 'upgrade' : null } |
        { 'install' : null },
      arg_1: Canister_settings,
      arg_2: Principal,
      arg_3: Array<number>,
    ) => Promise<Principal>,
  'getWasmHash' : () => Promise<Array<number>>,
  'reset' : () => Promise<undefined>,
  'updateDeployer' : (arg_0: Principal) => Promise<undefined>,
  'wallet_receive' : () => Promise<{ 'accepted' : bigint }>,
}
export interface _SERVICE extends LargeDeployer {}
