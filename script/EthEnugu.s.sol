// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {EthEnugu} from "../src/EthEnugu.sol";

contract EthEnuguScript is Script {
    EthEnugu public ethEnugu;

    function setUp() public {}

    function run() public {
       uint deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);
        ethEnugu = new EthEnugu("Eth Enugu NFT", "EENUGU");
        console.log("Eth Enugu contract deployed at:", address(ethEnugu));
        console.log("Deployer address:", deployer);
        vm.stopBroadcast();
    }
}
