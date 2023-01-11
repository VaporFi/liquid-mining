# Include .env file and export its .env vars
# (`-include` to ignore error if it does not exist)
-include .env

.PHONY: all test

# Libraries
update:; forge update

# Build & Tests
build         		:; forge build
test          		:; forge test -vvv
coverage      		:; forge coverage
trace         		:; forge test -vvvv
watch         		:; forge test --watch src test -vvv
clean         		:; forge clean
snapshot      		:; forge snapshot --match-path "test/solidity/Gas/**/*"

# Deploy
deploy_fuji 	 		:; forge script script/DeployFuji.s.sol:DeployFuji --rpc-url https://api.avax-test.network/ext/bc/C/rpc --broadcast --verify --etherscan-api-key $(SNOWTRACE_API_KEY)