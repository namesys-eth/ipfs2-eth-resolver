// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "src/Resolver.sol";

contract IsTestMainnet is Script {
    function run() external {
        vm.startBroadcast();

        /// @dev : Deploy
        Resolver resolver = new Resolver();
        vm.stopBroadcast();
        resolver;
    }
}
