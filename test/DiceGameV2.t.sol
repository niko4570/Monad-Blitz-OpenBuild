// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DiceGameV2} from "../src/DiceGameV2.sol";

contract DiceGameV2Test is Test {
    DiceGameV2 public diceGame;
    address public player1;
    address public player2;
    address public player3;
    address public roomBuilder;

    event RoomCreated(uint256 indexed roomId, uint256 maxPlayers, address indexed builder);
    event PlayerJoined(uint256 indexed roomId, address indexed player, uint256 playerCount);
    event GameStarted(uint256 indexed roomId, uint256 playerCount);
    event GameFinished(uint256 indexed roomId, address indexed winner, uint256[] diceResults);
    event RoomDeleted(uint256 indexed roomId, address indexed builder);
    event DiceRolled(uint256 indexed roomId, address indexed player, uint256 result);

    function setUp() public {
        diceGame = new DiceGameV2();
        player1 = makeAddr("player1");
        player2 = makeAddr("player2");
        player3 = makeAddr("player3");
        roomBuilder = makeAddr("roomBuilder");

        vm.deal(player1, 1 ether);
        vm.deal(player2, 1 ether);
        vm.deal(player3, 1 ether);
        vm.deal(roomBuilder, 1 ether);
    }

    // =========== Room Creation Tests ===========

    function testCreateRoom() public {
        vm.startPrank(roomBuilder);

        vm.expectEmit(true, true, false, true);
        emit RoomCreated(0, 3, roomBuilder);

        uint256 roomId = diceGame.createRoom(3);

        assertEq(roomId, 0);
        assertEq(diceGame.nextRoomId(), 1);

        (
            uint256 id,
            uint256 maxPlayers,
            address[] memory players,
            DiceGameV2.RoomStatus status,
            address winner,
            uint256[] memory diceResults,
            address builder,
            uint256 createdAt,
            uint256 finishedAt
        ) = diceGame.getRoomInfo(roomId);

        assertEq(id, 0);
        assertEq(maxPlayers, 3);
        assertEq(players.length, 0);
        assertTrue(status == DiceGameV2.RoomStatus.Active);
        assertEq(winner, address(0));
        assertEq(diceResults.length, 0);
        assertEq(builder, roomBuilder);
        assertGt(createdAt, 0);
        assertEq(finishedAt, 0);

        vm.stopPrank();
    }

    function testCreateRoomWithInvalidParameters() public {
        vm.startPrank(roomBuilder);

        // Test with 0 players
        vm.expectRevert("Players must be between 1 and 10");
        diceGame.createRoom(0);

        // Test with more than 10 players
        vm.expectRevert("Players must be between 1 and 10");
        diceGame.createRoom(11);

        vm.stopPrank();
    }

    function testMultipleRoomCreation() public {
        vm.startPrank(roomBuilder);

        uint256 room1 = diceGame.createRoom(2);
        uint256 room2 = diceGame.createRoom(3);
        uint256 room3 = diceGame.createRoom(4);

        assertEq(room1, 0);
        assertEq(room2, 1);
        assertEq(room3, 2);
        assertEq(diceGame.nextRoomId(), 3);

        uint256[] memory builderRooms = diceGame.getRoomsByBuilder(roomBuilder);
        assertEq(builderRooms.length, 3);
        assertEq(builderRooms[0], 0);
        assertEq(builderRooms[1], 1);
        assertEq(builderRooms[2], 2);

        vm.stopPrank();
    }

    // =========== Player Joining Tests ===========

    function testJoinRoom() public {
        // Create room
        vm.prank(roomBuilder);
        uint256 roomId = diceGame.createRoom(3);

        // Player1 joins
        vm.startPrank(player1);

        vm.expectEmit(true, true, false, true);
        emit PlayerJoined(roomId, player1, 1);

        diceGame.joinRoom(roomId);

        address[] memory players = diceGame.getPlayers(roomId);
        assertEq(players.length, 1);
        assertEq(players[0], player1);
        assertTrue(diceGame.playerJoined(player1, roomId));

        vm.stopPrank();

        // Player2 joins
        vm.prank(player2);
        diceGame.joinRoom(roomId);

        players = diceGame.getPlayers(roomId);
        assertEq(players.length, 2);
        assertEq(players[1], player2);
    }

    function testJoinNonExistentRoom() public {
        vm.prank(player1);
        vm.expectRevert("Room does not exist");
        diceGame.joinRoom(999);
    }

    function testJoinRoomTwice() public {
        vm.prank(roomBuilder);
        uint256 roomId = diceGame.createRoom(3);

        vm.startPrank(player1);
        diceGame.joinRoom(roomId);

        vm.expectRevert("Already joined this room");
        diceGame.joinRoom(roomId);

        vm.stopPrank();
    }

    function testJoinFullRoom() public {
        vm.prank(roomBuilder);
        uint256 roomId = diceGame.createRoom(2);

        vm.prank(player1);
        diceGame.joinRoom(roomId);

        vm.prank(player2);
        diceGame.joinRoom(roomId);

        vm.prank(player3);
        vm.expectRevert("Room is full");
        diceGame.joinRoom(roomId);
    }

    // =========== Game Playing Tests ===========

    function testStartGame() public {
        // Create room and add players
        vm.prank(roomBuilder);
        uint256 roomId = diceGame.createRoom(2);

        vm.prank(player1);
        diceGame.joinRoom(roomId);

        vm.prank(player2);
        diceGame.joinRoom(roomId);

        // Start game
        vm.startPrank(roomBuilder);

        vm.expectEmit(true, false, false, true);
        emit GameStarted(roomId, 2);

        address winner = diceGame.startGame(roomId);

        // Check that winner is one of the players
        assertTrue(winner == player1 || winner == player2);

        // Check room status
        (, , , DiceGameV2.RoomStatus status, , , , , ) = diceGame.getRoomInfo(roomId);
        assertTrue(status == DiceGameV2.RoomStatus.Finished);

        vm.stopPrank();
    }

    function testStartGameWithNoPlayers() public {
        vm.prank(roomBuilder);
        uint256 roomId = diceGame.createRoom(2);

        vm.prank(roomBuilder);
        vm.expectRevert("No players in room");
        diceGame.startGame(roomId);
    }

    function testStartGameUnauthorized() public {
        vm.prank(roomBuilder);
        uint256 roomId = diceGame.createRoom(2);

        vm.prank(player1);
        diceGame.joinRoom(roomId);

        vm.prank(player3); // Not builder or player
        vm.expectRevert("Only room builder or players can start game");
        diceGame.startGame(roomId);
    }

    function testStartAlreadyStartedGame() public {
        vm.prank(roomBuilder);
        uint256 roomId = diceGame.createRoom(2);

        vm.prank(player1);
        diceGame.joinRoom(roomId);

        vm.prank(roomBuilder);
        diceGame.startGame(roomId);

        vm.prank(roomBuilder);
        vm.expectRevert("Room is not in active state");
        diceGame.startGame(roomId);
    }

    // =========== Room Deletion Tests ===========

    function testDeleteRoom() public {
        vm.prank(roomBuilder);
        uint256 roomId = diceGame.createRoom(2);

        vm.startPrank(roomBuilder);

        vm.expectEmit(true, true, false, true);
        emit RoomDeleted(roomId, roomBuilder);

        diceGame.deleteRoom(roomId);

        (, , , DiceGameV2.RoomStatus status, , , , , ) = diceGame.getRoomInfo(roomId);
        assertTrue(status == DiceGameV2.RoomStatus.Deleted);

        // Check that room is removed from builder's list
        uint256[] memory builderRooms = diceGame.getRoomsByBuilder(roomBuilder);
        assertEq(builderRooms.length, 0);

        vm.stopPrank();
    }

    function testDeleteRoomUnauthorized() public {
        vm.prank(roomBuilder);
        uint256 roomId = diceGame.createRoom(2);

        vm.prank(player1);
        vm.expectRevert("Only room builder can perform this action");
        diceGame.deleteRoom(roomId);
    }

    function testDeleteStartedRoom() public {
        vm.prank(roomBuilder);
        uint256 roomId = diceGame.createRoom(2);

        vm.prank(player1);
        diceGame.joinRoom(roomId);

        vm.prank(roomBuilder);
        diceGame.startGame(roomId);

        vm.prank(roomBuilder);
        vm.expectRevert("Can only delete active rooms");
        diceGame.deleteRoom(roomId);
    }

    // =========== View Function Tests ===========

    function testGetActiveRooms() public {
        vm.startPrank(roomBuilder);

        uint256 room1 = diceGame.createRoom(2);
        uint256 room2 = diceGame.createRoom(3);
        uint256 room3 = diceGame.createRoom(4);

        uint256[] memory activeRooms = diceGame.getActiveRooms();
        assertEq(activeRooms.length, 3);
        assertEq(activeRooms[0], room1);
        assertEq(activeRooms[1], room2);
        assertEq(activeRooms[2], room3);

        // Delete one room
        diceGame.deleteRoom(room2);

        activeRooms = diceGame.getActiveRooms();
        assertEq(activeRooms.length, 2);
        assertEq(activeRooms[0], room1);
        assertEq(activeRooms[1], room3);

        vm.stopPrank();
    }

    function testGetPlayerStats() public {
        vm.prank(roomBuilder);
        uint256 roomId = diceGame.createRoom(2);

        vm.prank(player1);
        diceGame.joinRoom(roomId);

        vm.prank(player2);
        diceGame.joinRoom(roomId);

        // Initially no stats
        (uint256 wins, uint256 gamesPlayed) = diceGame.getPlayerStats(player1);
        assertEq(wins, 0);
        assertEq(gamesPlayed, 0);

        // Play game
        vm.prank(roomBuilder);
        address winner = diceGame.startGame(roomId);

        // Check winner stats
        (wins, gamesPlayed) = diceGame.getPlayerStats(winner);
        assertEq(wins, 1);
        assertEq(gamesPlayed, 1);

        // Check loser stats
        address loser = (winner == player1) ? player2 : player1;
        (wins, gamesPlayed) = diceGame.getPlayerStats(loser);
        assertEq(wins, 0);
        assertEq(gamesPlayed, 1);
    }

    function testGetTotalStats() public {
        // Initially no stats
        (uint256 totalRooms, uint256 totalGames, uint256 activeRooms) = diceGame.getTotalStats();
        assertEq(totalRooms, 0);
        assertEq(totalGames, 0);
        assertEq(activeRooms, 0);

        // Create rooms
        vm.startPrank(roomBuilder);
        diceGame.createRoom(2);
        diceGame.createRoom(3);

        (totalRooms, totalGames, activeRooms) = diceGame.getTotalStats();
        assertEq(totalRooms, 2);
        assertEq(totalGames, 0);
        assertEq(activeRooms, 2);

        vm.stopPrank();

        // Play a game
        vm.prank(player1);
        diceGame.joinRoom(0);

        vm.prank(player2);
        diceGame.joinRoom(0);

        vm.prank(roomBuilder);
        diceGame.startGame(0);

        (totalRooms, totalGames, activeRooms) = diceGame.getTotalStats();
        assertEq(totalRooms, 2);
        assertEq(totalGames, 1);
        assertEq(activeRooms, 1); // One room finished, one still active
    }

    // =========== Legacy Compatibility Tests ===========

    function testGetWinnerLegacyFunction() public {
        vm.prank(roomBuilder);
        uint256 roomId = diceGame.createRoom(2);

        vm.prank(player1);
        diceGame.joinRoom(roomId);

        vm.prank(player2);
        diceGame.joinRoom(roomId);

        // Test legacy getWinner function
        vm.prank(roomBuilder);
        address winner = diceGame.getWinner(roomId);

        assertTrue(winner == player1 || winner == player2);

        (, , , DiceGameV2.RoomStatus status, , , , , ) = diceGame.getRoomInfo(roomId);
        assertTrue(status == DiceGameV2.RoomStatus.Finished);
    }

    // =========== Randomness Tests ===========

    function testRandomnessDistribution() public {
        // Create multiple games to test randomness distribution
        uint256 totalGames = 50;
        uint256[7] memory diceCount; // Index 0 unused, 1-6 for dice values

        for (uint256 i = 0; i < totalGames; i++) {
            vm.prank(roomBuilder);
            uint256 roomId = diceGame.createRoom(1);

            vm.prank(player1);
            diceGame.joinRoom(roomId);

            vm.prank(roomBuilder);
            diceGame.startGame(roomId);

            // Get dice results
            (, , , , , uint256[] memory diceResults, , , ) = diceGame.getRoomInfo(roomId);

            if (diceResults.length > 0) {
                diceCount[diceResults[0]]++;
            }
        }

        // Each dice value should appear at least once in 50 games
        for (uint256 i = 1; i <= 6; i++) {
            assertGt(diceCount[i], 0, "Dice value should appear at least once");
        }

        console.log(string(abi.encodePacked("Dice distribution over ", vm.toString(totalGames), " games:")));
        for (uint256 i = 1; i <= 6; i++) {
            console.log(string(abi.encodePacked("Dice ", vm.toString(i), ": ", vm.toString(diceCount[i]), " times")));
        }
    }

    // =========== Access Control Tests ===========

    function testOwnershipFunctions() public {
        address owner = diceGame.owner();
        assertEq(owner, address(this));

        // Test emergency pause (should not revert for owner)
        diceGame.emergencyPause();

        // Test update random seed
        diceGame.updateRandomSeed();

        // Test with non-owner
        vm.prank(player1);
        vm.expectRevert();
        diceGame.emergencyPause();

        vm.prank(player1);
        vm.expectRevert();
        diceGame.updateRandomSeed();
    }

    // =========== Edge Cases Tests ===========

    function testSinglePlayerGame() public {
        vm.prank(roomBuilder);
        uint256 roomId = diceGame.createRoom(1);

        vm.prank(player1);
        diceGame.joinRoom(roomId);

        vm.prank(roomBuilder);
        address winner = diceGame.startGame(roomId);

        assertEq(winner, player1);

        // Check game results
        DiceGameV2.GameResult[] memory results = diceGame.getGameResults(roomId);
        assertEq(results.length, 1);
        assertEq(results[0].player, player1);
        assertGe(results[0].diceRoll, 1);
        assertLe(results[0].diceRoll, 6);
    }

    function testMaxPlayersGame() public {
        vm.prank(roomBuilder);
        uint256 roomId = diceGame.createRoom(10);

        // Add 10 players
        address[10] memory players = [
            makeAddr("p1"), makeAddr("p2"), makeAddr("p3"), makeAddr("p4"), makeAddr("p5"),
            makeAddr("p6"), makeAddr("p7"), makeAddr("p8"), makeAddr("p9"), makeAddr("p10")
        ];

        for (uint256 i = 0; i < 10; i++) {
            vm.prank(players[i]);
            diceGame.joinRoom(roomId);
        }

        vm.prank(roomBuilder);
        address winner = diceGame.startGame(roomId);

        // Winner should be one of the players
        bool isValidWinner = false;
        for (uint256 i = 0; i < 10; i++) {
            if (winner == players[i]) {
                isValidWinner = true;
                break;
            }
        }
        assertTrue(isValidWinner);

        // Check all dice results
        DiceGameV2.GameResult[] memory results = diceGame.getGameResults(roomId);
        assertEq(results.length, 10);

        for (uint256 i = 0; i < 10; i++) {
            assertGe(results[i].diceRoll, 1);
            assertLe(results[i].diceRoll, 6);
        }
    }

    // =========== Fuzz Tests ===========

    function testFuzzCreateRoom(uint256 maxPlayers) public {
        vm.assume(maxPlayers >= 1 && maxPlayers <= 10);

        vm.prank(roomBuilder);
        uint256 roomId = diceGame.createRoom(maxPlayers);

        (, uint256 roomMaxPlayers, , , , , , , ) = diceGame.getRoomInfo(roomId);
        assertEq(roomMaxPlayers, maxPlayers);
    }

    function testFuzzJoinAndPlay(uint8 numPlayers) public {
        vm.assume(numPlayers >= 1 && numPlayers <= 10);

        vm.prank(roomBuilder);
        uint256 roomId = diceGame.createRoom(numPlayers);

        // Create and add players
        address[] memory players = new address[](numPlayers);
        for (uint256 i = 0; i < numPlayers; i++) {
            players[i] = makeAddr(string(abi.encodePacked("fuzzPlayer", i)));
            vm.prank(players[i]);
            diceGame.joinRoom(roomId);
        }

        vm.prank(roomBuilder);
        address winner = diceGame.startGame(roomId);

        // Verify winner is one of the players
        bool foundWinner = false;
        for (uint256 i = 0; i < numPlayers; i++) {
            if (winner == players[i]) {
                foundWinner = true;
                break;
            }
        }
        assertTrue(foundWinner);
    }
}