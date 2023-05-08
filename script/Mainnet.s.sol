// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "src/IPFS2ETH.sol";

contract IsTestMainnet is Script {
    function run() external {
        vm.startBroadcast();

        /// @dev : Deploy
        IPFS2ETH resolver = new IPFS2ETH();
        vm.stopBroadcast();
        resolver;
    }
}
