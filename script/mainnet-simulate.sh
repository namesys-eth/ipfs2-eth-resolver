forge fmt && source .env && forge script ./script/Goerli.s.sol --rpc-url $GOERLI_RPC_URL --private-key $GOERLI_PRIVATE_KEY -vvv RUST_BACKTRACE=full
