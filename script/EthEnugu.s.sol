// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {EthEnugu} from "../src/EthEnugu.sol";

contract EthEnuguScript is Script {
    EthEnugu public ethEnugu;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        ethEnugu = new EthEnugu("POAP NFT", "POAP");

        vm.stopBroadcast();
    }
}
