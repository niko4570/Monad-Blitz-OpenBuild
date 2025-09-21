// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DiceGame} from "../src/DiceGame.sol";
import {DiceGameV2} from "../src/DiceGameV2.sol";

contract DeployDiceGame is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy original version for compatibility
        DiceGame diceGame = new DiceGame();

        // Deploy enhanced version with security improvements
        DiceGameV2 diceGameV2 = new DiceGameV2();

        vm.stopBroadcast();

        console.log("=== Deployment Results ===");
        console.log("DiceGame (Original) deployed at:", address(diceGame));
        console.log("DiceGameV2 (Enhanced) deployed at:", address(diceGameV2));
        console.log("Deployed on Monad Testnet");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", msg.sender);
        console.log("=========================");

        // Display key improvements
        console.log("DiceGameV2 Features:");
        console.log("- Secure pseudo-random number generation");
        console.log("- Enhanced access control and security");
        console.log("- Comprehensive room management");
        console.log("- Rich statistics and game history");
        console.log("- Event-driven architecture");
    }
}