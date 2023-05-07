// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "src/Resolver.sol";

contract CCIP2ETHGoerli is Script {
    //iENS public ENS = iENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

    function run() external {
        vm.startBroadcast();

        /// @dev : Deploy
        Resolver resolver = new Resolver();

        /// @dev : Set resolver on testnet name
        //bytes32 namehash =
        //    keccak256(abi.encodePacked(keccak256(abi.encodePacked(bytes32(0), keccak256("eth"))), keccak256("ccip2")));
        //ENS.setResolver(namehash, address(resolver));
        vm.stopBroadcast();
        resolver;
    }
}
