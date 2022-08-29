## DFINITY UI Canister and deploy script

Package based [Azure key vault identity](https://github.com/ORIGYN-SA/identity-azure-key-vault). 
Package supports 2 different types of canisters:
- WASM - simple canister with backend or business logic
- Asset - Ui canister methods with uploading,receiving,sending static source code

!! Before using must install packages and compile code to JS from TS. Executing from project root
```bash
 node scripts/deploy/build/cli.js -c "test" -w "rwlgt-iiaaa-aaaaa-aaaaa-cai" -m "./scripts/deploy/target/wasm32-unknown-unknown/release/ui.wasm" -t "install" -C 960000000 -T "asset"
 
 
 node scripts/deploy/build/cli.js 
 # -c,--canister-id - (quoted string) canister ID you want to upgrade 
 # -w, --wallet-id - (quoted string) wallet canister ID you will take for deploing for DFX server (local or mainnet)
 # -m, --module - (quoted string) path to wasm module you want to upload (if you will deploy asset canister - need to take ui_canister_optimized.wasm. It's certified asset canister (look Rust source code)
 # -t, --type -  (quoted string) type of installing canister. Supports next values: install, upgrade, reinstall
 # -h, --host - (quoted string) host address for installing canister (configure without schema)
 # -C, --cycles - (integer) Cycles for canister you're deploing
 # -T, --canister-type - (quoted string) canister type what you deploing. Support next value: wasm,asset
 # -a, --asset-path - (quoted string) path to source code if you're deploying asset canister
```
