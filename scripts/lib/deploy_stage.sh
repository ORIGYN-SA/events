#!/usr/bin/env bash

set -o xtrace

DEPLOYER="node scripts/deployer-gov/build/main.js"

cd scripts/deployer-gov || exit 1
npm i
npm run start:build
cd ../../

DEPLOYER_WASM="scripts/large_canister_deployer.wasm"
dfx identity use admin
ADMIN_PRINCIPAL=$(dfx identity get-principal)
DEPLOYER_EXTRA_METHOD="addAdmin"
DEPLOYER_EXTRA_ARG=$(scripts/didc-linux64 encode "(principal \"${ADMIN_PRINCIPAL}\" )" -d scripts/deployer-gov/src/large_canister_deployer/large_canister_deployer.did)

${DEPLOYER} \
  -d "${DEPLOYER_WASM}" \
  -w "${WALLET_ID}" \
  -m ".dfx/local/canisters/drout/drout.wasm" \
  -t "${ACTION}" \
  -C 200000000000 \
  -T "wasm" \
  -h "${ICP_URL}" \
  -e "${DEPLOYER_EXTRA_ARG}" \
  -f "${DEPLOYER_EXTRA_METHOD}"
