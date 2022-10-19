
dfx build test_publisher
dfx build test_runner

gzip ./.dfx/local/canisters/test_runner/test_runner.wasm -f
gzip ./.dfx/local/canisters/test_publisher/test_publisher.wasm -f