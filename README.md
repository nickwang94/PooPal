# PooPal

记录便便频率的 iPhone 小应用（SwiftUI + SwiftData，iOS 17+，无需登录，数据只存在本机）。

## 运行

首次使用 Xcode 需要先同意许可协议：

```bash
sudo xcodebuild -license accept
```

- Xcode：打开 `PooPal.xcodeproj`，选择 `PooPal` scheme 和任意 iPhone 模拟器，⌘R 运行，⌘U 跑测试。
- 想看带示例数据的界面：Product → Scheme → Edit Scheme → Run → Arguments，勾选 `-demoData`（使用内存数据，不会写入真实记录）。

## 命令行

```bash
# 单元测试
xcodebuild test -project PooPal.xcodeproj -scheme PooPal -destination 'platform=iOS Simulator,name=iPhone 17'

# 构建 + 在模拟器中运行并截图到 screenshots/
scripts/screenshots.sh "iPhone 17"

# 不依赖 xcodebuild，直接用工具链在 macOS 上跑统计逻辑测试
scripts/run-logic-tests-macos.sh

# 重新生成应用图标（由应用内的 PooPal 字标渲染，含浅色 / 深色 / 着色三版）
scripts/render-app-icon.sh
```

## 结构

- `Shared/`：App 和小组件共用的代码（SwiftData 模型、App Group 数据库位置与 v1 数据迁移、统计、布里斯托分型、提醒、一键记录的 AppIntent、设计 token 与字标）
- `PooPal/`：App 界面（首页、记录日历 / 列表 / 趋势、编辑记录、设置与备份）
- `PooPalWidget/`：桌面小组件（iOS 17 可交互小组件，一键记录）
- `Config/`：权限文件（App Group `group.com.nickwang.PooPal`）和小组件 Info.plist
- `PooPalTests/`：单元测试

## 签名

使用免费的 Personal Team（`S9PC78X8QG`）自动签名。免费团队的描述文件 7 天过期，过期后重新运行一次安装即可，数据不会丢。
首次为真机构建需要 `-allowProvisioningUpdates`，让 Xcode 自动为 App 和小组件申请 App Group。

## 截图专用启动参数

`-appearance light|dark`（外观）、`-demoData`（内存示例数据）、`-emptyStore`（内存空数据）、`-startTab history`、`-historyMode list|trends`、`-homeScroll stats`、`-showAddEntry YES`、`-showSettings YES`。

## 设计

视觉规范见 `DESIGN.md`（颜色 token、瓷砖组件、浅色 / 深色）。产品定位见 `PRODUCT.md`。外观可在 设置 › 显示 › 外观 中切换：跟随系统、浅色、深色。
