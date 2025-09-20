// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DiceGame} from "../src/DiceGame.sol";

contract TestDiceGame is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address diceGameAddress = vm.envAddress("DICE_GAME_ADDRESS");

        DiceGame diceGame = DiceGame(diceGameAddress);

        vm.startBroadcast(deployerPrivateKey);

        console.log("Testing DiceGame contract at:", diceGameAddress);
        console.log("Current nextRoomId:", diceGame.nextRoomId());

        // Test 1: Create a room
        console.log("Creating a room with max 3 players...");
        uint256 roomId = diceGame.createRoom(3);
        console.log("Room created with ID:", roomId);
        console.log("Room builder:", diceGame.getRoomBuilder(roomId));

        // Test 2: Join the room
        console.log("Joining room...");
        diceGame.joinRoom(roomId);
        console.log("Joined room successfully");

        // Test 3: Check players
        address[] memory players = diceGame.getPlayers(roomId);
        console.log("Number of players in room:", players.length);
        console.log("Player 1:", players[0]);

        // Test 4: Get winner (this will start the game)
        console.log("Getting winner...");
        address winner = diceGame.getWinner(roomId);
        console.log("Winner:", winner);

        // Test 5: Check room state
        (, , bool started, bool finished, address roomWinner,,) = diceGame.rooms(roomId);
        console.log("Room started:", started);
        console.log("Room finished:", finished);
        console.log("Room winner:", roomWinner);

        vm.stopBroadcast();

        console.log("All tests completed successfully on Monad Testnet!");
    }
}