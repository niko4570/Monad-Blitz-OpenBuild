// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {DiceGame} from "../src/DiceGame.sol";

contract DiceGameFuzzTest is Test {
    DiceGame public diceGame;
    address public owner;

    function setUp() public {
        owner = makeAddr("owner");
        vm.prank(owner);
        diceGame = new DiceGame();
    }

    function testFuzz_CreateRoom(uint256 maxPlayers) public {
        // Test room creation with various max players
        vm.assume(maxPlayers > 0 && maxPlayers <= 1000); // Reasonable bounds

        uint256 initialRoomId = diceGame.nextRoomId();

        vm.prank(owner);
        uint256 roomId = diceGame.createRoom(maxPlayers);

        assertEq(roomId, initialRoomId);
        assertEq(diceGame.nextRoomId(), initialRoomId + 1);
        assertEq(diceGame.getRoomBuilder(roomId), owner);

        uint256[] memory builderRooms = diceGame.getRoomsByBuilder(owner);
        assertEq(builderRooms.length, 1);
        assertEq(builderRooms[0], roomId);

        // Check room state
        (uint256 storedRoomId, uint256 storedMaxPlayers, bool started, bool finished,,,) = diceGame.rooms(roomId);
        assertEq(storedRoomId, roomId);
        assertEq(storedMaxPlayers, maxPlayers);
        assertFalse(started);
        assertFalse(finished);
    }

    function testFuzz_CreateRoom_RevertZeroPlayers(uint256 maxPlayers) public {
        vm.assume(maxPlayers == 0);

        vm.prank(owner);
        vm.expectRevert("At least 1 player required");
        diceGame.createRoom(maxPlayers);
    }

    function testFuzz_CreateMultipleRooms(uint8 numRooms, uint256 maxPlayers) public {
        vm.assume(numRooms > 0 && numRooms <= 20); // Reasonable bounds for gas
        vm.assume(maxPlayers > 0 && maxPlayers <= 100);

        uint256 initialRoomId = diceGame.nextRoomId();

        vm.startPrank(owner);
        for (uint256 i = 0; i < numRooms; i++) {
            uint256 roomId = diceGame.createRoom(maxPlayers);
            assertEq(roomId, initialRoomId + i);
        }
        vm.stopPrank();

        assertEq(diceGame.nextRoomId(), initialRoomId + numRooms);

        uint256[] memory builderRooms = diceGame.getRoomsByBuilder(owner);
        assertEq(builderRooms.length, numRooms);
    }

    function testFuzz_JoinRoom(uint256 roomId, address player) public {
        vm.assume(player != address(0));
        vm.assume(roomId < 1000); // Reasonable bound

        // First create a room
        vm.prank(owner);
        uint256 actualRoomId = diceGame.createRoom(10);

        // Use the actual room ID for testing
        vm.prank(player);
        diceGame.joinRoom(actualRoomId);

        address[] memory players = diceGame.getPlayers(actualRoomId);
        assertEq(players.length, 1);
        assertEq(players[0], player);

        // Verify player is marked as joined
        assertTrue(diceGame.playerJoined(player, actualRoomId));
    }

    function testFuzz_JoinRoom_MultipleUniqueAddresses(address[5] memory players) public {
        // Ensure all addresses are unique and not zero
        for (uint256 i = 0; i < players.length; i++) {
            vm.assume(players[i] != address(0));
            for (uint256 j = i + 1; j < players.length; j++) {
                vm.assume(players[i] != players[j]);
            }
        }

        vm.prank(owner);
        uint256 roomId = diceGame.createRoom(10);

        // All players join the room
        for (uint256 i = 0; i < players.length; i++) {
            vm.prank(players[i]);
            diceGame.joinRoom(roomId);
        }

        address[] memory roomPlayers = diceGame.getPlayers(roomId);
        assertEq(roomPlayers.length, players.length);

        // Verify all players are in the room
        for (uint256 i = 0; i < players.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < roomPlayers.length; j++) {
                if (roomPlayers[j] == players[i]) {
                    found = true;
                    break;
                }
            }
            assertTrue(found, "Player not found in room");
            assertTrue(diceGame.playerJoined(players[i], roomId));
        }
    }

    function testFuzz_JoinRoom_RevertAlreadyJoined(address player) public {
        vm.assume(player != address(0));

        vm.prank(owner);
        uint256 roomId = diceGame.createRoom(10);

        vm.prank(player);
        diceGame.joinRoom(roomId);

        // Try to join again - should revert
        vm.prank(player);
        vm.expectRevert("Already joined this room");
        diceGame.joinRoom(roomId);
    }

    function testFuzz_GetWinner(address[3] memory players, uint256 timestamp) public {
        // Ensure all addresses are unique and not zero
        for (uint256 i = 0; i < players.length; i++) {
            vm.assume(players[i] != address(0));
            for (uint256 j = i + 1; j < players.length; j++) {
                vm.assume(players[i] != players[j]);
            }
        }

        vm.assume(timestamp > 0 && timestamp < type(uint256).max / 2);

        vm.prank(owner);
        uint256 roomId = diceGame.createRoom(5);

        // All players join
        for (uint256 i = 0; i < players.length; i++) {
            vm.prank(players[i]);
            diceGame.joinRoom(roomId);
        }

        // Set specific timestamp for deterministic test
        vm.warp(timestamp);

        vm.prank(owner);
        address winner = diceGame.getWinner(roomId);

        // Winner should be one of the players
        bool isValidWinner = false;
        for (uint256 i = 0; i < players.length; i++) {
            if (winner == players[i]) {
                isValidWinner = true;
                break;
            }
        }
        assertTrue(isValidWinner, "Winner is not one of the players");

        // Check room state after getting winner
        (,, bool started, bool finished, address roomWinner,,) = diceGame.rooms(roomId);
        assertTrue(started);
        assertTrue(finished);
        assertEq(roomWinner, winner);
    }

    function testFuzz_GetWinner_RevertAlreadyStarted(address player) public {
        vm.assume(player != address(0));

        vm.prank(owner);
        uint256 roomId = diceGame.createRoom(5);

        vm.prank(player);
        diceGame.joinRoom(roomId);

        vm.prank(owner);
        diceGame.getWinner(roomId);

        // Try to get winner again - should revert
        vm.prank(owner);
        vm.expectRevert("Already started");
        diceGame.getWinner(roomId);
    }

    function testFuzz_DeleteRoom(uint256 maxPlayers) public {
        vm.assume(maxPlayers > 0 && maxPlayers <= 100);

        vm.prank(owner);
        uint256 roomId = diceGame.createRoom(maxPlayers);

        vm.prank(owner);
        diceGame.deleteRoom(roomId);

        uint256[] memory builderRooms = diceGame.getRoomsByBuilder(owner);
        assertEq(builderRooms.length, 0);

        // Check room state is reset
        (uint256 storedRoomId,, bool started, bool finished,,,) = diceGame.rooms(roomId);
        assertEq(storedRoomId, 0);
        assertFalse(started);
        assertFalse(finished);
    }

    function testFuzz_DeleteRoom_RevertStartedRoom(address player) public {
        vm.assume(player != address(0));

        vm.prank(owner);
        uint256 roomId = diceGame.createRoom(5);

        vm.prank(player);
        diceGame.joinRoom(roomId);

        vm.prank(owner);
        diceGame.getWinner(roomId);

        // Try to delete started room - should revert
        vm.prank(owner);
        vm.expectRevert("Cannot delete a started room");
        diceGame.deleteRoom(roomId);
    }

    function testFuzz_MultiplePlayersMultipleRooms(
        uint8 numRooms,
        uint8 numPlayers,
        uint256 seed
    ) public {
        vm.assume(numRooms > 0 && numRooms <= 10);
        vm.assume(numPlayers > 0 && numPlayers <= 10);
        vm.assume(seed > 0 && seed <= type(uint160).max - numPlayers - 1); // Prevent overflow in address creation

        uint256[] memory roomIds = new uint256[](numRooms);

        // Create multiple rooms
        vm.startPrank(owner);
        for (uint256 i = 0; i < numRooms; i++) {
            roomIds[i] = diceGame.createRoom(numPlayers * 2); // Ensure enough capacity
        }
        vm.stopPrank();

        // Generate unique players and have them join rooms
        for (uint256 i = 0; i < numPlayers; i++) {
            address player = address(uint160(seed + i + 1)); // Ensure non-zero address with safe bounds
            uint256 roomIndex = i % numRooms;

            vm.prank(player);
            diceGame.joinRoom(roomIds[roomIndex]);
        }

        // Verify room states
        for (uint256 i = 0; i < numRooms; i++) {
            address[] memory players = diceGame.getPlayers(roomIds[i]);
            // Calculate expected players for this room based on distribution
            uint256 expectedPlayers = numPlayers / numRooms;
            if (i < numPlayers % numRooms) {
                expectedPlayers += 1; // Distribute remainder evenly
            }
            assertEq(players.length, expectedPlayers);
        }
    }

    function testFuzz_RandomnessConsistency(
        address player1,
        address player2,
        uint256 timestamp
    ) public {
        vm.assume(player1 != address(0) && player2 != address(0));
        vm.assume(player1 != player2);
        vm.assume(timestamp > 0 && timestamp < type(uint256).max / 2);

        // Create two identical rooms
        vm.prank(owner);
        uint256 roomId1 = diceGame.createRoom(3);

        vm.prank(owner);
        uint256 roomId2 = diceGame.createRoom(3);

        // Same players join both rooms
        vm.prank(player1);
        diceGame.joinRoom(roomId1);
        vm.prank(player2);
        diceGame.joinRoom(roomId1);

        vm.prank(player1);
        diceGame.joinRoom(roomId2);
        vm.prank(player2);
        diceGame.joinRoom(roomId2);

        // Set same timestamp for both
        vm.warp(timestamp);

        // Get winners
        vm.prank(owner);
        address winner1 = diceGame.getWinner(roomId1);

        vm.warp(timestamp); // Reset to same timestamp
        vm.prank(owner);
        address winner2 = diceGame.getWinner(roomId2);

        // With same timestamp and same players in same order, winners should be the same
        assertEq(winner1, winner2, "Randomness should be consistent with same inputs");
    }

    function testFuzz_EdgeCase_MaxUint256Values(uint256 largeValue) public {
        // Test with very large values to check for overflow issues
        vm.assume(largeValue > 1000 && largeValue < type(uint128).max); // Avoid extreme values that might cause gas issues

        vm.prank(owner);
        uint256 roomId = diceGame.createRoom(largeValue);

        // Should not overflow or cause issues
        assertEq(diceGame.getRoomBuilder(roomId), owner);

        // Check room state
        (uint256 storedRoomId, uint256 storedMaxPlayers,,,,,) = diceGame.rooms(roomId);
        assertEq(storedRoomId, roomId);
        assertEq(storedMaxPlayers, largeValue);
    }

    function testFuzz_StateTransitions(
        address player,
        uint256 maxPlayers,
        uint256 timestamp
    ) public {
        vm.assume(player != address(0));
        vm.assume(maxPlayers > 0 && maxPlayers <= 100);
        vm.assume(timestamp > 0 && timestamp < type(uint256).max / 2);

        vm.prank(owner);
        uint256 roomId = diceGame.createRoom(maxPlayers);

        // Initial state
        (,, bool initialStarted, bool initialFinished,,,) = diceGame.rooms(roomId);
        assertFalse(initialStarted);
        assertFalse(initialFinished);

        // After joining
        vm.prank(player);
        diceGame.joinRoom(roomId);

        (,, bool afterJoinStarted, bool afterJoinFinished,,,) = diceGame.rooms(roomId);
        assertFalse(afterJoinStarted);
        assertFalse(afterJoinFinished);

        // After getting winner
        vm.warp(timestamp);
        vm.prank(owner);
        address winner = diceGame.getWinner(roomId);

        (,, bool finalStarted, bool finalFinished, address finalWinner,,) = diceGame.rooms(roomId);
        assertTrue(finalStarted);
        assertTrue(finalFinished);
        assertEq(finalWinner, winner);

        // Should not be able to join after started
        address newPlayer = makeAddr("newPlayer");
        vm.prank(newPlayer);
        vm.expectRevert("Game already started");
        diceGame.joinRoom(roomId);
    }
}