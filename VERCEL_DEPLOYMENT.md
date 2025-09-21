# 🚀 Vercel 部署指南

## 快速部署步驟

### 方法 1：GitHub 連接部署（推薦）

1. **登入 Vercel**
   - 訪問 [vercel.com](https://vercel.com)
   - 使用 GitHub 賬號登入

2. **導入項目**
   - 點擊 "New Project"
   - 選擇你的 GitHub 倉庫：`Monad-Blitz-OpenBuild`
   - 點擊 "Import"

3. **配置項目**
   - Project Name: `dicegame-v2` 或你喜歡的名字
   - Framework Preset: `Other` (保持默認)
   - Root Directory: `./` (默認)
   - Build Command: 留空或 `echo "Static site"`
   - Output Directory: `./` (默認)
   - Install Command: 留空

4. **部署**
   - 點擊 "Deploy"
   - 等待 1-2 分鐘完成部署

### 方法 2：CLI 部署

1. **安裝 Vercel CLI**
   ```bash
   npm i -g vercel
   ```

2. **登入 Vercel**
   ```bash
   vercel login
   ```

3. **部署項目**
   ```bash
   # 在項目根目錄執行
   vercel

   # 按提示操作：
   # ? Set up and deploy "~/monad-test"? [Y/n] y
   # ? Which scope do you want to deploy to? [選擇你的賬號]
   # ? Link to existing project? [N/y] n
   # ? What's your project's name? dicegame-v2
   # ? In which directory is your code located? ./
   ```

4. **生產環境部署**
   ```bash
   vercel --prod
   ```

## 📁 部署文件結構

```
project-root/
├── index.html                 # 主頁面 ⭐
├── dice-game-demo.html        # 基礎版本
├── dice-game-v2-demo.html     # 增強版本
├── dice-game-v2-enhanced.html # 終極版本
├── contract-test.html         # 測試工具
├── contract-config.js         # 配置文件
├── vercel.json               # Vercel 配置 ⭐
├── package.json              # 項目信息
├── .vercelignore            # 忽略文件
└── README*.md               # 文檔
```

## 🔧 Vercel 配置說明

### vercel.json 功能
- ✅ 靜態文件服務
- ✅ 自定義路由（友好的 URL）
- ✅ 安全頭設置
- ✅ CORS 配置

### 路由配置
- `/` → 主頁面
- `/basic` → 基礎版本
- `/enhanced` → 增強版本
- `/ultimate` → 終極版本
- `/test` → 連接測試

## 🌐 部署後設置

### 1. 自定義域名（可選）
1. 在 Vercel Dashboard 中選擇項目
2. 進入 "Settings" → "Domains"
3. 添加你的自定義域名
4. 配置 DNS 記錄

### 2. 環境變量（如需要）
1. 進入 "Settings" → "Environment Variables"
2. 添加必要的環境變量（目前項目不需要）

### 3. 性能優化
- ✅ 自動 CDN 分發
- ✅ 自動 HTTPS
- ✅ 自動壓縮
- ✅ 邊緣網絡加速

## 📊 部署後驗證

1. **訪問主頁**
   - 檢查 `https://your-domain.vercel.app`
   - 確認所有版本鏈接正常

2. **功能測試**
   - 測試 MetaMask 連接
   - 驗證合約交互
   - 檢查各個版本功能

3. **性能檢查**
   - 使用 [PageSpeed Insights](https://pagespeed.web.dev/)
   - 檢查載入速度

## 🔄 自動部署

### GitHub 集成
- ✅ 推送到 main/master 分支自動部署
- ✅ Pull Request 預覽部署
- ✅ 分支預覽環境

### 部署預覽
```bash
# 每次 git push 都會觸發新部署
git add .
git commit -m "update: improve UI"
git push origin master

# Vercel 會自動：
# 1. 檢測到推送
# 2. 開始新部署
# 3. 更新生產環境
```

## 🐛 常見問題

### 1. 部署失敗
- 檢查 `vercel.json` 語法
- 確認沒有敏感信息在代碼中
- 查看 Vercel 控制台錯誤日誌

### 2. 路由不工作
- 確認 `vercel.json` 路由配置正確
- 檢查文件名是否匹配

### 3. MetaMask 連接問題
- 確認是 HTTPS 部署（Vercel 自動提供）
- 檢查瀏覽器控制台錯誤
- 驗證合約地址是否正確

### 4. 性能問題
- 檢查圖片是否過大
- 確認 JavaScript 文件大小
- 使用 Vercel Analytics 監控

## 📈 SEO 優化

### 已包含的優化
- ✅ Meta tags
- ✅ Open Graph tags
- ✅ Twitter Card tags
- ✅ 語義化 HTML
- ✅ 響應式設計

### 進一步優化
1. 添加 `sitemap.xml`
2. 配置 `robots.txt`
3. 使用結構化數據
4. 優化圖片格式

## 🎯 成功部署檢查清單

- [ ] Vercel 項目創建成功
- [ ] GitHub 倉庫連接正常
- [ ] 主頁面載入正常
- [ ] 所有遊戲版本可訪問
- [ ] MetaMask 連接功能正常
- [ ] 合約交互測試通過
- [ ] 移動端界面正常
- [ ] HTTPS 證書生效
- [ ] 自定義域名配置（如需要）
- [ ] 性能測試通過

## 🎉 部署完成

恭喜！你的 DiceGame V2.0 現在已經在 Vercel 上線了！

**接下來可以：**
1. 🎮 分享給朋友一起玩
2. 📱 在社交媒體推廣
3. 🔧 持續改進和更新
4. 📊 監控使用情況

---

**需要幫助？**
- [Vercel 文檔](https://vercel.com/docs)
- [GitHub Issues](https://github.com/niko4570/Monad-Blitz-OpenBuild/issues)
- [Discord 社群](https://discord.gg/monad)