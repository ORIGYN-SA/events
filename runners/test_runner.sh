set -ex

dfx identity new test_nft_ref || true
dfx identity use test_nft_ref

ADMIN_PRINCIPAL=$(dfx identity get-principal)
ADMIN_ACCOUNTID=$(dfx ledger account-id)

echo $ADMIN_PRINCIPAL
echo $ADMIN_ACCOUNTID

bash ./runners/create_canisters.sh

TEST_RUNNER_CANISTER_ID=$(dfx canister id test_runner)
TEST_RUNNER_ACCOUNT_ID=$(python3 principal_to_accountid.py $TEST_RUNNER_CANISTER_ID)

TEST_PUBLISHER_CANISTER_ID=$(dfx canister id test_publisher)
TEST_PUBLISHER_ACCOUNT_ID=$(python3 principal_to_accountid.py $TEST_PUBLISHER_CANISTER_ID)


bash ./runners/build_canisters.sh

dfx canister install test_publisher --mode=reinstall --wasm ./.dfx/local/canisters/test_publisher/test_publisher.wasm.gz  --argument "()"

dfx canister install test_runner --mode=reinstall --wasm ./.dfx/local/canisters/test_runner/test_runner.wasm.gz --argument "(record{ test_publisher = principal \"$TEST_PUBLISHER_CANISTER_ID\";})"



TEST_RUNNER_ID=$(dfx canister id test_runner)

echo $TEST_RUNNER_ID

dfx canister call test_runner test
#dfx canister call test_runner_nft test
#dfx canister call test_runner_data_nft test
#dfx canister call test_runner_utils_nft test

