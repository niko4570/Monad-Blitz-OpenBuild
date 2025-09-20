// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DiceGame} from "../src/DiceGame.sol";

contract SimulateDeployment is Script {
    function run() external {
        // 使用預設私鑰進行模擬
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

        vm.startBroadcast(deployerPrivateKey);

        console.log("Simulating DiceGame deployment...");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", msg.sender);

        DiceGame diceGame = new DiceGame();

        console.log("DiceGame deployed at:", address(diceGame));
        console.log("Initial nextRoomId:", diceGame.nextRoomId());

        // 模擬一些基本操作
        console.log("\nTesting basic functionality:");

        // 創建房間
        uint256 roomId = diceGame.createRoom(3);
        console.log("Created room with ID:", roomId);

        // 加入房間
        diceGame.joinRoom(roomId);
        console.log("Joined room successfully");

        // 檢查玩家
        address[] memory players = diceGame.getPlayers(roomId);
        console.log("Number of players:", players.length);

        // 獲取獲勝者
        address winner = diceGame.getWinner(roomId);
        console.log("Winner:", winner);

        vm.stopBroadcast();

        console.log("\nSimulation completed successfully!");
        console.log("Ready for Monad Testnet deployment");
    }
}