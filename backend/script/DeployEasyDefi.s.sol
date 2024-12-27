// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {EasyDefi} from "../src/EasyDefi.sol";

contract DeployEasyDefi is Script {
    function run() external returns (EasyDefi) {
        vm.startBroadcast();
        EasyDefi easydefi = new EasyDefi(msg.sender);
        vm.stopBroadcast();
        return easydefi;
    }
}
