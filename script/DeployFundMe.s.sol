// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
 
import {Script} from "forge-std/Script.sol";
import {SimpleVotingSystem} from "../src/SimpleVotingSystem.sol";
 
contract DeployFundMe is Script {
 
    function run() external returns (SimpleVotingSystem){
 
        vm.startBroadcast();
        SimpleVotingSystem fundMe = new SimpleVotingSystem();
        vm.stopBroadcast();
        return fundMe;
    }
 
}