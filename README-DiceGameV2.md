# 🎲 DiceGame V2.0 - 卡通骰子大冒險

一個功能豐富、安全可靠的多人骰子遊戲智能合約，具有精美的卡通風格前端界面。

## 📋 目錄

- [功能概覽](#功能概覽)
- [技術亮點](#技術亮點)
- [快速開始](#快速開始)
- [智能合約架構](#智能合約架構)
- [前端功能](#前端功能)
- [部署指南](#部署指南)
- [測試](#測試)
- [安全性](#安全性)
- [API 文檔](#api-文檔)
- [故障排除](#故障排除)

## 🚀 功能概覽

### 核心功能
- **🏠 房間管理**: 創建、加入、刪除遊戲房間
- **🎮 多人遊戲**: 支援 1-10 人同時遊戲
- **🎲 公平遊戲**: 安全的偽隨機數生成
- **📊 實時統計**: 個人戰績和全局統計
- **🏆 遊戲歷史**: 完整的遊戲記錄追蹤
- **🔐 權限控制**: 完善的訪問控制機制

### 前端特色
- **🎨 卡通風格**: 精美的 UI 設計和動畫效果
- **🔊 音效體驗**: 豐富的音效和背景音樂
- **📱 響應式設計**: 支援桌面和移動設備
- **⚡ 實時更新**: 基於事件的實時狀態更新
- **🎊 互動體驗**: 粒子效果和慶祝動畫

## 🔧 技術亮點

### 智能合約安全性
- **🛡️ 重入保護**: 使用 ReentrancyGuard 防止重入攻擊
- **🔒 訪問控制**: 基於 Ownable 的權限管理
- **🎯 安全隨機數**: 增強的偽隨機數生成算法
- **✅ 輸入驗證**: 全面的參數檢查和狀態驗證

### 架構設計
- **📦 模組化設計**: 清晰的合約結構和功能分離
- **🔄 狀態管理**: 完善的房間狀態機制
- **📡 事件驅動**: 豐富的事件系統支援前端實時更新
- **🔧 可擴展性**: 預留擴展接口和升級機制

## 🚀 快速開始

### 前置需求

```bash
# 安裝 Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# 安裝 Node.js (可選，用於前端開發)
# https://nodejs.org/
```

### 環境設置

1. **克隆項目**
```bash
git clone <repository-url>
cd monad-test
```

2. **安裝依賴**
```bash
forge install
```

3. **環境配置**
```bash
# 複製環境變量文件
cp .env.example .env

# 編輯 .env 文件，設置你的私鑰
PRIVATE_KEY=your_private_key_here
```

### 編譯和測試

```bash
# 編譯合約
forge build

# 運行測試
forge test

# 運行測試並顯示詳細輸出
forge test -vvv

# 生成覆蓋率報告
forge coverage
```

### 部署合約

```bash
# 部署到本地測試網絡
anvil # 在另一個終端運行

# 部署合約
forge script script/DeployDiceGame.s.sol --rpc-url http://localhost:8545 --broadcast

# 部署到 Monad 測試網
forge script script/DeployDiceGame.s.sol --rpc-url $MONAD_RPC_URL --broadcast --verify
```

## 🏗️ 智能合約架構

### 核心合約：DiceGameV2

```solidity
contract DiceGameV2 is ReentrancyGuard, Ownable {
    // 房間狀態枚舉
    enum RoomStatus { Active, Started, Finished, Deleted }

    // 房間結構
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

    // 遊戲結果結構
    struct GameResult {
        address player;
        uint256 diceRoll;
        uint256 timestamp;
    }
}
```

### 主要功能模組

#### 1. 房間管理
- `createRoom(uint256 maxPlayers)`: 創建新房間
- `joinRoom(uint256 roomId)`: 加入房間
- `deleteRoom(uint256 roomId)`: 刪除房間（僅房主）

#### 2. 遊戲執行
- `startGame(uint256 roomId)`: 開始遊戲
- `_executeGame(uint256 roomId)`: 內部遊戲邏輯
- `_generateSecureRandom()`: 安全隨機數生成

#### 3. 查詢功能
- `getRoomInfo(uint256 roomId)`: 獲取房間詳細信息
- `getActiveRooms()`: 獲取所有活躍房間
- `getPlayerStats(address player)`: 獲取玩家統計
- `getTotalStats()`: 獲取全局統計

## 🎨 前端功能

### 三個版本的前端界面

1. **dice-game-demo.html** - 基礎版本
   - 基本的合約交互功能
   - 簡單的卡通風格界面

2. **dice-game-v2-demo.html** - 增強版本
   - 房間大廳和實時更新
   - 完整的統計面板
   - 遊戲歷史記錄

3. **dice-game-v2-enhanced.html** - 最強版本
   - 音效和背景音樂系統
   - 粒子效果和高級動畫
   - 響應式設計和暗色模式支援

### 主要功能特色

#### 🎵 音效系統
```javascript
class SoundManager {
    // Web Audio API 音效管理
    // 支援音效切換和背景音樂
    // 多種互動音效（點擊、骰子、勝利等）
}
```

#### ✨ 粒子效果
```javascript
class ParticleSystem {
    // 動態粒子效果
    // 勝利慶祝動畫
    // 互動反饋效果
}
```

#### 📊 實時數據更新
- 自動刷新統計數據
- 事件監聽實時更新
- 智能緩存機制

## 📝 API 文檔

### 智能合約 ABI

完整的 ABI 定義請參考前端文件中的 `ABI` 常量。

### 主要函數簽名

```solidity
// 寫入函數
function createRoom(uint256 _maxPlayers) external returns (uint256);
function joinRoom(uint256 roomId) external;
function startGame(uint256 roomId) external returns (address);
function deleteRoom(uint256 roomId) external;

// 查詢函數
function getRoomInfo(uint256 roomId) external view returns (...);
function getActiveRooms() external view returns (uint256[] memory);
function getPlayerStats(address player) external view returns (uint256, uint256);
function getTotalStats() external view returns (uint256, uint256, uint256);
```

### 事件定義

```solidity
event RoomCreated(uint256 indexed roomId, uint256 maxPlayers, address indexed builder);
event PlayerJoined(uint256 indexed roomId, address indexed player, uint256 playerCount);
event GameStarted(uint256 indexed roomId, uint256 playerCount);
event GameFinished(uint256 indexed roomId, address indexed winner, uint256[] diceResults);
event RoomDeleted(uint256 indexed roomId, address indexed builder);
event DiceRolled(uint256 indexed roomId, address indexed player, uint256 result);
```

## 🧪 測試

### 測試套件概覽

我們提供了全面的測試套件 (`test/DiceGameV2.t.sol`)，包括：

#### 功能測試
- ✅ 房間創建和管理
- ✅ 玩家加入和權限控制
- ✅ 遊戲執行和結果驗證
- ✅ 統計數據準確性

#### 安全測試
- ✅ 訪問控制驗證
- ✅ 重入攻擊防護
- ✅ 輸入驗證測試
- ✅ 邊界條件測試

#### 隨機性測試
- ✅ 隨機數分佈驗證
- ✅ 公平性測試
- ✅ 重複性檢查

#### 模糊測試
- ✅ 參數範圍測試
- ✅ 極端情況處理
- ✅ 性能壓力測試

### 運行測試

```bash
# 運行所有測試
forge test

# 運行特定測試
forge test --match-test testCreateRoom

# 運行測試並顯示 gas 使用
forge test --gas-report

# 運行覆蓋率測試
forge coverage --report debug
```

### 測試結果示例

```
Running 25 tests for test/DiceGameV2.t.sol:DiceGameV2Test
[PASS] testCreateRoom() (gas: 185432)
[PASS] testJoinRoom() (gas: 267543)
[PASS] testStartGame() (gas: 345678)
[PASS] testRandomnessDistribution() (gas: 12456789)
...

Test result: ok. 25 passed; 0 failed; finished in 1.23s
```

## 🔒 安全性

### 安全措施

1. **重入保護**
   - 使用 OpenZeppelin 的 `ReentrancyGuard`
   - 關鍵函數添加 `nonReentrant` 修飾符

2. **訪問控制**
   - 基於 `Ownable` 的權限管理
   - 房間建立者專有權限
   - 參與者身份驗證

3. **輸入驗證**
   - 全面的參數檢查
   - 狀態轉換驗證
   - 邊界條件處理

4. **隨機數安全**
   - 多因子隨機數生成
   - 避免區塊變量依賴
   - 種子更新機制

### 已知限制

1. **偽隨機數**
   - 當前使用鏈上偽隨機數
   - 生產環境建議使用 Chainlink VRF

2. **Gas 成本**
   - 大型房間可能產生較高 Gas 費用
   - 建議限制最大玩家數量

## 🚀 部署指南

### 本地部署

1. **啟動本地測試網**
```bash
anvil --host 0.0.0.0 --port 8545
```

2. **部署合約**
```bash
forge script script/DeployDiceGame.s.sol \
  --rpc-url http://localhost:8545 \
  --broadcast \
  --private-key $PRIVATE_KEY
```

3. **更新前端配置**
```javascript
// 在前端文件中更新合約地址
const CONTRACT_ADDRESS = "0x部署後的合約地址";
```

### Monad 測試網部署

1. **配置網絡**
```bash
# 添加到 foundry.toml
[rpc_endpoints]
monad_testnet = "https://testnet-rpc.monad.xyz"
```

2. **部署和驗證**
```bash
forge script script/DeployDiceGame.s.sol \
  --rpc-url monad_testnet \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

### 生產環境部署檢查清單

- [ ] 完整測試套件通過
- [ ] 安全審計完成
- [ ] Gas 優化驗證
- [ ] 前端配置更新
- [ ] 監控系統設置
- [ ] 應急計劃準備

## 🛠️ 故障排除

### 常見問題

#### 1. 合約部署失敗
```bash
# 檢查 Gas 限制
forge script --gas-limit 5000000 ...

# 檢查私鑰配置
echo $PRIVATE_KEY
```

#### 2. 前端連接問題
```javascript
// 檢查網絡配置
const network = await provider.getNetwork();
console.log("Current network:", network);

// 檢查合約地址
console.log("Contract address:", CONTRACT_ADDRESS);
```

#### 3. 隨機數問題
```solidity
// 在測試中驗證隨機數分佈
function testRandomnessDistribution() public {
    // 運行多次遊戲並檢查結果分佈
}
```

#### 4. Gas 費用過高
- 減少房間最大玩家數
- 優化事件參數
- 考慮分批處理

### 調試技巧

1. **使用 Foundry 調試**
```bash
forge test --debug testFunctionName
```

2. **前端調試**
```javascript
// 啟用詳細日誌
console.log("Transaction:", tx);
console.log("Receipt:", receipt);
```

3. **事件監聽調試**
```javascript
// 監聽所有事件
contract.on("*", (event) => {
    console.log("Event:", event);
});
```

## 🤝 貢獻指南

### 開發流程

1. Fork 項目
2. 創建功能分支
3. 編寫測試
4. 實現功能
5. 提交 Pull Request

### 代碼標準

- 遵循 Solidity 最佳實踐
- 100% 測試覆蓋率
- 詳細的函數註釋
- Gas 優化考量

## 📄 許可證

MIT License - 詳見 [LICENSE](LICENSE) 文件

## 🙏 致謝

- [Foundry](https://github.com/foundry-rs/foundry) - 開發框架
- [OpenZeppelin](https://openzeppelin.com/) - 安全合約庫
- [Ethers.js](https://ethers.org/) - 以太坊庫
- [Monad](https://monad.xyz/) - 部署平台

---

**📞 支援**: 如有問題，請提交 [Issue](https://github.com/your-repo/issues) 或聯繫開發團隊。

**🌟 Star**: 如果這個項目對你有幫助，請給我們一個 Star！