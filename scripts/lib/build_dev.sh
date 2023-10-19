#!/usr/bin/env bash

set -o xtrace
set -e

echo "Modify identity to admin"

dfx start --background

dfx identity use default

mkdir ~/.config/dfx/identity/admin/
echo ${DFX_IDENTITY} > ~/.config/dfx/identity/admin/identity.pem
sed -i 's/\\r\\n/\r\n/g' ~/.config/dfx/identity/admin/identity.pem

dfx identity use admin

echo "Build canister"

dfx canister --network local create --all
dfx build --network local --all

