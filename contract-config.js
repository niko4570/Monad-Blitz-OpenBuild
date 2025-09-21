// DiceGame 合約配置文件
// 部署到 Monad Testnet

const CONTRACT_CONFIG = {
    // Monad Testnet 配置
    NETWORK: {
        CHAIN_ID: 41,
        NAME: "Monad Testnet",
        RPC_URL: "https://testnet-rpc.monad.xyz",
        BLOCK_EXPLORER: "https://testnet-explorer.monad.xyz",
        CURRENCY: {
            NAME: "MON",
            SYMBOL: "MON",
            DECIMALS: 18
        }
    },

    // 合約地址
    CONTRACTS: {
        DICE_GAME_V1: "0x5Cf84Ad10D2ecb4BD0303BA1d3715a4A13BFeB3c", // 原始版本
        DICE_GAME_V2: "0xAa3e0954f3b665e84c3baE5e159A27FF70edf955", // 增強版本 (已部署)
    },

    // 前端配置
    UI: {
        AUTO_REFRESH_INTERVAL: 30000, // 30秒
        MAX_PLAYERS_DISPLAY: 10,
        SOUND_ENABLED: true,
        ANIMATION_ENABLED: true
    },

    // Gas 配置
    GAS: {
        CREATE_ROOM: 200000,
        JOIN_ROOM: 100000,
        START_GAME: 500000,
        DELETE_ROOM: 150000
    }
};

// 導出配置
if (typeof module !== 'undefined' && module.exports) {
    module.exports = CONTRACT_CONFIG;
} else if (typeof window !== 'undefined') {
    window.CONTRACT_CONFIG = CONTRACT_CONFIG;
}