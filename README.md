# PooPal 💩

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

# 重新生成应用图标（由应用内的吉祥物视图渲染）
scripts/render-app-icon.sh
```

## 结构

- `PooPal/Logic/PoopStats.swift`：频率统计（纯函数，可注入 `now` 和日历）
- `PooPal/Models/PoopEntry.swift`：SwiftData 模型
- `PooPal/Views/`：首页、记录（日历 / 列表）、补记、吉祥物
- `PooPalTests/`：统计逻辑单元测试
