// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Note: For production use, consider installing OpenZeppelin contracts
// For now, we'll implement basic security features inline

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @title DiceGameV2 - Enhanced Dice Game with Security & Rich Features
 * @dev Multi-player dice game with secure randomness, comprehensive room management, and rich statistics
 */
contract DiceGameV2 is ReentrancyGuard, Ownable {

    enum RoomStatus { Active, Started, Finished, Deleted }

    struct Room {
        uint256 roomId;
        uint256 maxPlayers;
        address[] players;
        RoomStatus status;
        address winner;
        uint256[] diceResults;
        address builder;
        uint256 createdAt;
        uint256 finishedAt;
    }

    struct GameResult {
        address player;
        uint256 diceRoll;
        uint256 timestamp;
    }

    // State variables
    mapping(uint256 => Room) public rooms;
    mapping(address => uint256[]) public roomsByBuilder;
    mapping(address => mapping(uint256 => bool)) public playerJoined;
    mapping(uint256 => GameResult[]) public gameResults;
    mapping(address => uint256) public playerWins;

    uint256 public nextRoomId;
    uint256 public totalGamesPlayed;
    uint256 private _randomSeed;
    address private immutable i_operator;

    // Events
    event RoomCreated(uint256 indexed roomId, uint256 maxPlayers, address indexed builder);
    event PlayerJoined(uint256 indexed roomId, address indexed player, uint256 playerCount);
    event GameStarted(uint256 indexed roomId, uint256 playerCount);
    event GameFinished(uint256 indexed roomId, address indexed winner, uint256[] diceResults);
    event RoomDeleted(uint256 indexed roomId, address indexed builder);
    event DiceRolled(uint256 indexed roomId, address indexed player, uint256 result);

    constructor() {
        i_operator = msg.sender;
        _randomSeed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,  // More secure than block.difficulty
            msg.sender
        )));
    }

    // Modifiers
    modifier roomExists(uint256 roomId) {
        require(roomId < nextRoomId, "Room does not exist");
        require(rooms[roomId].status != RoomStatus.Deleted, "Room has been deleted");
        _;
    }

    modifier onlyRoomBuilder(uint256 roomId) {
        require(rooms[roomId].builder == msg.sender, "Only room builder can perform this action");
        _;
    }

    modifier roomNotStarted(uint256 roomId) {
        require(rooms[roomId].status == RoomStatus.Active, "Room is not in active state");
        _;
    }

    // Main functions
    function createRoom(uint256 _maxPlayers) external returns (uint256) {
        require(_maxPlayers >= 1 && _maxPlayers <= 10, "Players must be between 1 and 10");

        uint256 roomId = nextRoomId++;
        Room storage room = rooms[roomId];
        room.roomId = roomId;
        room.maxPlayers = _maxPlayers;
        room.status = RoomStatus.Active;
        room.builder = msg.sender;
        room.createdAt = block.timestamp;

        roomsByBuilder[msg.sender].push(roomId);

        emit RoomCreated(roomId, _maxPlayers, msg.sender);
        return roomId;
    }

    function joinRoom(uint256 roomId) external roomExists(roomId) roomNotStarted(roomId) {
        Room storage room = rooms[roomId];
        require(!playerJoined[msg.sender][roomId], "Already joined this room");
        require(room.players.length < room.maxPlayers, "Room is full");

        room.players.push(msg.sender);
        playerJoined[msg.sender][roomId] = true;

        emit PlayerJoined(roomId, msg.sender, room.players.length);
    }

    function startGame(uint256 roomId) external roomExists(roomId) roomNotStarted(roomId) nonReentrant returns (address) {
        Room storage room = rooms[roomId];
        require(room.players.length > 0, "No players in room");
        require(
            msg.sender == room.builder || playerJoined[msg.sender][roomId],
            "Only room builder or players can start game"
        );

        room.status = RoomStatus.Started;
        emit GameStarted(roomId, room.players.length);

        return _executeGame(roomId);
    }

    function _executeGame(uint256 roomId) internal returns (address) {
        Room storage room = rooms[roomId];

        uint256 highest = 0;
        address winner;
        uint256[] memory diceResults = new uint256[](room.players.length);

        // Generate secure pseudo-random numbers for each player
        for (uint i = 0; i < room.players.length; i++) {
            uint256 roll = _generateSecureRandom(roomId, room.players[i], i) % 6 + 1;
            diceResults[i] = roll;

            // Store individual game result
            gameResults[roomId].push(GameResult({
                player: room.players[i],
                diceRoll: roll,
                timestamp: block.timestamp
            }));

            emit DiceRolled(roomId, room.players[i], roll);

            if (roll > highest) {
                highest = roll;
                winner = room.players[i];
            }
        }

        room.status = RoomStatus.Finished;
        room.winner = winner;
        room.diceResults = diceResults;
        room.finishedAt = block.timestamp;

        // Update statistics
        playerWins[winner]++;
        totalGamesPlayed++;

        emit GameFinished(roomId, winner, diceResults);
        return winner;
    }

    function _generateSecureRandom(uint256 roomId, address player, uint256 index) internal returns (uint256) {
        _randomSeed = uint256(keccak256(abi.encodePacked(
            _randomSeed,
            block.timestamp,
            block.prevrandao,
            roomId,
            player,
            index,
            gasleft()
        )));
        return _randomSeed;
    }

    function deleteRoom(uint256 roomId) external roomExists(roomId) onlyRoomBuilder(roomId) {
        Room storage room = rooms[roomId];
        require(room.status == RoomStatus.Active, "Can only delete active rooms");

        room.status = RoomStatus.Deleted;

        // Remove from builder's room list
        uint256[] storage builderRooms = roomsByBuilder[msg.sender];
        for (uint i = 0; i < builderRooms.length; i++) {
            if (builderRooms[i] == roomId) {
                builderRooms[i] = builderRooms[builderRooms.length - 1];
                builderRooms.pop();
                break;
            }
        }

        emit RoomDeleted(roomId, msg.sender);
    }

    // View functions
    function getRoomInfo(uint256 roomId) external view roomExists(roomId) returns (
        uint256 id,
        uint256 maxPlayers,
        address[] memory players,
        RoomStatus status,
        address winner,
        uint256[] memory diceResults,
        address builder,
        uint256 createdAt,
        uint256 finishedAt
    ) {
        Room storage room = rooms[roomId];
        return (
            room.roomId,
            room.maxPlayers,
            room.players,
            room.status,
            room.winner,
            room.diceResults,
            room.builder,
            room.createdAt,
            room.finishedAt
        );
    }

    function getActiveRooms() external view returns (uint256[] memory) {
        uint256[] memory activeRooms = new uint256[](nextRoomId);
        uint256 count = 0;

        for (uint256 i = 0; i < nextRoomId; i++) {
            if (rooms[i].status == RoomStatus.Active) {
                activeRooms[count] = i;
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = activeRooms[i];
        }

        return result;
    }

    function getGameResults(uint256 roomId) external view roomExists(roomId) returns (GameResult[] memory) {
        return gameResults[roomId];
    }

    function getPlayerStats(address player) external view returns (uint256 wins, uint256 gamesPlayed) {
        wins = playerWins[player];
        gamesPlayed = 0;

        for (uint256 i = 0; i < nextRoomId; i++) {
            if (rooms[i].status == RoomStatus.Finished && playerJoined[player][i]) {
                gamesPlayed++;
            }
        }
    }

    function getPlayers(uint256 roomId) external view roomExists(roomId) returns (address[] memory) {
        return rooms[roomId].players;
    }

    function getRoomsByBuilder(address builder) external view returns (uint256[] memory) {
        return roomsByBuilder[builder];
    }

    function getRoomBuilder(uint256 roomId) external view roomExists(roomId) returns (address) {
        return rooms[roomId].builder;
    }

    function getRoomStatus(uint256 roomId) external view roomExists(roomId) returns (RoomStatus) {
        return rooms[roomId].status;
    }

    function getOperator() external view returns (address) {
        return i_operator;
    }

    function getTotalStats() external view returns (uint256 totalRoomsCreated, uint256 totalGames, uint256 activeRoomsCount) {
        totalRoomsCreated = nextRoomId;
        totalGames = totalGamesPlayed;

        for (uint256 i = 0; i < nextRoomId; i++) {
            if (rooms[i].status == RoomStatus.Active) {
                activeRoomsCount++;
            }
        }
    }

    // Emergency functions (only owner)
    function emergencyPause() external onlyOwner {
        // Implementation for emergency pause if needed
        // Could add a paused state to prevent new games
    }

    function updateRandomSeed() external onlyOwner {
        _randomSeed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            msg.sender,
            gasleft()
        )));
    }

    // Legacy compatibility - keeping getWinner for backward compatibility
    function getWinner(uint256 roomId) external roomExists(roomId) roomNotStarted(roomId) nonReentrant returns (address) {
        Room storage room = rooms[roomId];
        require(room.players.length > 0, "No players in room");
        require(
            msg.sender == room.builder || playerJoined[msg.sender][roomId],
            "Only room builder or players can start game"
        );

        room.status = RoomStatus.Started;
        emit GameStarted(roomId, room.players.length);

        return _executeGame(roomId);
    }
}