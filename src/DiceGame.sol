// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DiceGame  {
    
    struct Room {
        uint256 roomId;
        uint256 maxPlayers;
        address[] players;
        bool started;
        bool finished;
        address winner;
        uint256 vrfRequestId;
        address builder;
    }

    mapping(uint256 => Room) public rooms;
    mapping(uint256 => uint256) public vrfRequestToRoom;
    mapping(address => uint256[]) public roomsByBuilder;
    mapping(address => mapping(uint256 => bool)) public playerJoined;
    uint256 public nextRoomId;
    address private immutable i_operator;
    event RoomCreated(uint256 indexed roomId, uint256 maxPlayers);
    event PlayerJoined(uint256 indexed roomId, address player);
    event GameStarted(uint256 indexed roomId);
    event GameFinished(uint256 indexed roomId, address winner);
    event RandomnessRequested(uint256 indexed roomId, uint256 indexed requestId);

    constructor() {
        i_operator = msg.sender;
    }

    function createRoom(uint256 _maxPlayers) external returns (uint256) {
        require(_maxPlayers >= 1, "At least 1 player required");

        uint256 roomId = nextRoomId++;
        Room storage room = rooms[roomId];
        room.roomId = roomId;
        room.maxPlayers = _maxPlayers;
        room.builder = msg.sender;

        roomsByBuilder[msg.sender].push(roomId);

        emit RoomCreated(roomId, _maxPlayers);
        return roomId;
    }

    function joinRoom(uint256 roomId) external {
        Room storage room = rooms[roomId];
        require(!room.started, "Game already started");
        require(!playerJoined[msg.sender][roomId], "Already joined this room");

        room.players.push(msg.sender);
        playerJoined[msg.sender][roomId] = true;
        emit PlayerJoined(roomId, msg.sender);
    }

    function getWinner(uint256 roomId) external returns (address) {
        Room storage room = rooms[roomId];
        require(!room.started, "Already started");
        room.started = true;
        // 简化的随机数 (不安全)
        uint256 highest = 0;
        address winner;
        for (uint i = 0; i < room.players.length; i++) {
            uint256 roll = (uint256(
                keccak256(abi.encodePacked(block.timestamp, room.players[i], i))
            ) % 6) + 1;

            if (roll > highest) {
                highest = roll;
                winner = room.players[i];
            }
        }

        room.finished = true;
        room.winner = winner;

        emit GameFinished(roomId, winner);
        return winner;
    }

    function deleteRoom(uint256 roomId) external {
        Room storage room = rooms[roomId];
        require(!room.started, "Cannot delete a started room");
        
        delete rooms[roomId];

        uint256[] storage builderRooms = roomsByBuilder[msg.sender];
        for (uint i = 0; i < builderRooms.length; i++) {
            if (builderRooms[i] == roomId) {
                builderRooms[i] = builderRooms[builderRooms.length - 1];
                builderRooms.pop();
                break;
            }
        }
    }

    function getPlayers(uint256 roomId) external view returns (address[] memory) {
        return rooms[roomId].players;
    }

    function getRoomsByBuilder(address builder) external view returns (uint256[] memory) {
        return roomsByBuilder[builder];
    }

    function getRoomBuilder(uint256 roomId) external view returns (address) {
        return rooms[roomId].builder;
    }

    function getOperator() internal view returns (address) {
        return i_operator;
    }
}