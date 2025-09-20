// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DiceGame} from "../src/DiceGame.sol";

contract DeployDiceGame is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        DiceGame diceGame = new DiceGame();

        vm.stopBroadcast();

        console.log("DiceGame deployed at:", address(diceGame));
        console.log("Deployed on Monad Testnet");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", msg.sender);
    }
}