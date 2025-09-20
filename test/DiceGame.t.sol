// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {DiceGame} from "../src/DiceGame.sol";
import {DeployDiceGame} from "../script/DeployDiceGame.s.sol";

contract DiceGameTest is Test {
    DiceGame public diceGame;
    address public owner;
    address public player1;
    address public player2;
    address public player3;

    event RoomCreated(uint256 indexed roomId, uint256 maxPlayers);
    event PlayerJoined(uint256 indexed roomId, address player);
    event GameStarted(uint256 indexed roomId);
    event GameFinished(uint256 indexed roomId, address winner);
    event RandomnessRequested(uint256 indexed roomId, uint256 indexed requestId);

    function setUp() public {
        owner = makeAddr("owner");
        player1 = makeAddr("player1");
        player2 = makeAddr("player2");
        player3 = makeAddr("player3");

        vm.prank(owner);
        diceGame = new DiceGame();
    }

    function test_CreateRoom() public {
        vm.prank(player1);
        vm.expectEmit(true, true, false, true);
        emit RoomCreated(0, 3);

        uint256 roomId = diceGame.createRoom(3);

        assertEq(roomId, 0);
        assertEq(diceGame.nextRoomId(), 1);
        assertEq(diceGame.getRoomBuilder(roomId), player1);

        uint256[] memory builderRooms = diceGame.getRoomsByBuilder(player1);
        assertEq(builderRooms.length, 1);
        assertEq(builderRooms[0], roomId);
    }

    function test_CreateRoom_RevertWithZeroPlayers() public {
        vm.prank(player1);
        vm.expectRevert("At least 1 player required");
        diceGame.createRoom(0);
    }

    function test_CreateMultipleRooms() public {
        vm.startPrank(player1);
        uint256 roomId1 = diceGame.createRoom(2);
        uint256 roomId2 = diceGame.createRoom(4);
        vm.stopPrank();

        assertEq(roomId1, 0);
        assertEq(roomId2, 1);
        assertEq(diceGame.nextRoomId(), 2);

        uint256[] memory builderRooms = diceGame.getRoomsByBuilder(player1);
        assertEq(builderRooms.length, 2);
        assertEq(builderRooms[0], roomId1);
        assertEq(builderRooms[1], roomId2);
    }

    function test_JoinRoom() public {
        vm.prank(player1);
        uint256 roomId = diceGame.createRoom(3);

        vm.prank(player2);
        vm.expectEmit(true, true, false, true);
        emit PlayerJoined(roomId, player2);

        diceGame.joinRoom(roomId);

        address[] memory players = diceGame.getPlayers(roomId);
        assertEq(players.length, 1);
        assertEq(players[0], player2);
    }

    function test_JoinRoom_MultiplePlayers() public {
        vm.prank(player1);
        uint256 roomId = diceGame.createRoom(3);

        vm.prank(player2);
        diceGame.joinRoom(roomId);

        vm.prank(player3);
        diceGame.joinRoom(roomId);

        address[] memory players = diceGame.getPlayers(roomId);
        assertEq(players.length, 2);
        assertEq(players[0], player2);
        assertEq(players[1], player3);
    }

    function test_JoinRoom_RevertAlreadyStarted() public {
        vm.prank(player1);
        uint256 roomId = diceGame.createRoom(2);

        vm.prank(player2);
        diceGame.joinRoom(roomId);

        vm.prank(player1);
        diceGame.getWinner(roomId);

        vm.prank(player3);
        vm.expectRevert("Game already started");
        diceGame.joinRoom(roomId);
    }

    function test_GetWinner() public {
        vm.prank(player1);
        uint256 roomId = diceGame.createRoom(3);

        vm.prank(player2);
        diceGame.joinRoom(roomId);

        vm.prank(player3);
        diceGame.joinRoom(roomId);

        vm.prank(player1);
        vm.expectEmit(true, true, false, false);
        emit GameFinished(roomId, address(0));

        address winner = diceGame.getWinner(roomId);

        assertTrue(winner == player2 || winner == player3);

        (,, bool started, bool finished, address roomWinner,,) = diceGame.rooms(roomId);
        assertTrue(started);
        assertTrue(finished);
        assertEq(roomWinner, winner);
    }

    function test_GetWinner_RevertAlreadyStarted() public {
        vm.prank(player1);
        uint256 roomId = diceGame.createRoom(2);

        vm.prank(player2);
        diceGame.joinRoom(roomId);

        vm.prank(player1);
        diceGame.getWinner(roomId);

        vm.prank(player1);
        vm.expectRevert("Already started");
        diceGame.getWinner(roomId);
    }

    function test_GetWinner_SinglePlayer() public {
        vm.prank(player1);
        uint256 roomId = diceGame.createRoom(1);

        vm.prank(player2);
        diceGame.joinRoom(roomId);

        vm.prank(player1);
        address winner = diceGame.getWinner(roomId);

        assertEq(winner, player2);
    }

    function test_DeleteRoom() public {
        vm.prank(player1);
        uint256 roomId = diceGame.createRoom(3);

        vm.prank(player1);
        diceGame.deleteRoom(roomId);

        uint256[] memory builderRooms = diceGame.getRoomsByBuilder(player1);
        assertEq(builderRooms.length, 0);

        (uint256 storedRoomId, , bool started, bool finished, , , ) = diceGame.rooms(roomId);
        assertEq(storedRoomId, 0);
        assertFalse(started);
        assertFalse(finished);
    }

    function test_DeleteRoom_RevertStartedRoom() public {
        vm.prank(player1);
        uint256 roomId = diceGame.createRoom(2);

        vm.prank(player2);
        diceGame.joinRoom(roomId);

        vm.prank(player1);
        diceGame.getWinner(roomId);

        vm.prank(player1);
        vm.expectRevert("Cannot delete a started room");
        diceGame.deleteRoom(roomId);
    }

    function test_DeleteRoom_MultipleRooms() public {
        vm.startPrank(player1);
        uint256 roomId1 = diceGame.createRoom(2);
        uint256 roomId2 = diceGame.createRoom(3);
        uint256 roomId3 = diceGame.createRoom(4);

        diceGame.deleteRoom(roomId2);
        vm.stopPrank();

        uint256[] memory builderRooms = diceGame.getRoomsByBuilder(player1);
        assertEq(builderRooms.length, 2);

        bool foundRoom1 = false;
        bool foundRoom3 = false;
        for (uint i = 0; i < builderRooms.length; i++) {
            if (builderRooms[i] == roomId1) foundRoom1 = true;
            if (builderRooms[i] == roomId3) foundRoom3 = true;
        }
        assertTrue(foundRoom1);
        assertTrue(foundRoom3);
    }

    function test_GetPlayers_EmptyRoom() public {
        vm.prank(player1);
        uint256 roomId = diceGame.createRoom(3);

        address[] memory players = diceGame.getPlayers(roomId);
        assertEq(players.length, 0);
    }

    function test_GetRoomsByBuilder_EmptyBuilder() public view {
        uint256[] memory builderRooms = diceGame.getRoomsByBuilder(player1);
        assertEq(builderRooms.length, 0);
    }

    function test_GetRoomBuilder() public {
        vm.prank(player1);
        uint256 roomId = diceGame.createRoom(3);

        address builder = diceGame.getRoomBuilder(roomId);
        assertEq(builder, player1);
    }

    function test_GetRoomBuilder_NonExistentRoom() public view{
        address builder = diceGame.getRoomBuilder(999);
        assertEq(builder, address(0));
    }

    function test_NextRoomId_Increments() public {
        assertEq(diceGame.nextRoomId(), 0);

        vm.prank(player1);
        diceGame.createRoom(2);
        assertEq(diceGame.nextRoomId(), 1);

        vm.prank(player2);
        diceGame.createRoom(3);
        assertEq(diceGame.nextRoomId(), 2);
    }

    function test_RandomnessConsistency() public {
        vm.prank(player1);
        uint256 roomId = diceGame.createRoom(2);

        vm.prank(player2);
        diceGame.joinRoom(roomId);

        vm.prank(player3);
        diceGame.joinRoom(roomId);

        uint256 timestamp = block.timestamp;
        vm.warp(timestamp);

        vm.prank(player1);
        address winner1 = diceGame.getWinner(roomId);

        vm.prank(player1);
        uint256 roomId2 = diceGame.createRoom(2);

        vm.prank(player2);
        diceGame.joinRoom(roomId2);

        vm.prank(player3);
        diceGame.joinRoom(roomId2);

        vm.warp(timestamp);

        vm.prank(player1);
        address winner2 = diceGame.getWinner(roomId2);

        assertEq(winner1, winner2);
    }

    function test_RoomStateTransitions() public {
        vm.prank(player1);
        uint256 roomId = diceGame.createRoom(2);

        address[] memory initialPlayers = diceGame.getPlayers(roomId);
        (,, bool initialStarted, bool initialFinished,,,) = diceGame.rooms(roomId);
        assertEq(initialPlayers.length, 0);
        assertFalse(initialStarted);
        assertFalse(initialFinished);

        vm.prank(player2);
        diceGame.joinRoom(roomId);

        address[] memory playersAfterJoin = diceGame.getPlayers(roomId);
        (,, bool startedAfterJoin, bool finishedAfterJoin,,,) = diceGame.rooms(roomId);
        assertEq(playersAfterJoin.length, 1);
        assertFalse(startedAfterJoin);
        assertFalse(finishedAfterJoin);

        vm.prank(player1);
        diceGame.getWinner(roomId);

        (,, bool finalStarted, bool finalFinished,,,) = diceGame.rooms(roomId);
        assertTrue(finalStarted);
        assertTrue(finalFinished);
    }
}