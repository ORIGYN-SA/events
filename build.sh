#!/bin/sh

mkdir -p .dfx/local/canisters/droute &&

$(vessel bin)/moc src/actors/Main/main.mo -o .dfx/local/canisters/droute/droute.wasm \
-c --debug --idl --stable-types --public-metadata candid:service --actor-idl .dfx/local/canisters/idl/ \
--actor-alias droute $(dfx canister id droute) $(vessel sources) &&

ic-wasm .dfx/local/canisters/droute/droute.wasm -o .dfx/local/canisters/droute/droute.wasm shrink &&

gzip -f -9 .dfx/local/canisters/droute/droute.wasm
