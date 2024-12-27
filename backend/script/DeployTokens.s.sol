// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {AlyraToken} from "../src/AlyraToken.sol";
import {LiquidAlyraToken} from "../src/LiquidAlyraToken.sol";

contract DeployTokens is Script {
    function run() external returns (AlyraToken, LiquidAlyraToken) {
        vm.startBroadcast();
        AlyraToken alyraToken = new AlyraToken();
        LiquidAlyraToken liquidAlyraToken = new LiquidAlyraToken();
        vm.stopBroadcast();
        return (alyraToken, liquidAlyraToken);
    }
}
