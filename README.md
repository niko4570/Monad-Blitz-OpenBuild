# Monad Dice Game

A simple multiplayer dice game smart contract built for the Monad hackathon.

## Overview

Players can create rooms, join games, and compete by rolling virtual dice. The highest roll wins!

## Features

- **Create Rooms**: Set maximum player limits
- **Join Games**: Multiple players can join before game starts
- **Dice Rolling**: Simple random number generation for fair gameplay
- **Winner Selection**: Highest dice roll wins the game

## Contract Functions

- `createRoom(maxPlayers)` - Create a new game room
- `joinRoom(roomId)` - Join an existing room
- `getWinner(roomId)` - Start game and determine winner
- `getPlayers(roomId)` - View players in a room

## Quick Start

```bash
# Install dependencies
forge install

# Build contracts
forge build

# Run tests
forge test

# Deploy to Monad Testnet
forge script script/DeployDiceGame.s.sol --rpc-url monadTestnet --broadcast
```

Built with ❤️ for Monad