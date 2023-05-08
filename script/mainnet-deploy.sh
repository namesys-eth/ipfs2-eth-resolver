forge fmt && source .env && forge script ./script/Mainnet.s.sol --rpc-url $MAINNET_RPC_URL  --private-key $MAINNET_PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_KEY -vvv RUST_BACKTRACE=full