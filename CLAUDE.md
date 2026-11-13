# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

Countdown 是一个 macOS 屏幕保护程序（`.saver` bundle），fork 自 [Motivation](https://github.com/soffes/Motivation)。它在屏幕上显示距离目标日期的倒计时；如果目标日期已过去，则改为正计时（`abs()` 处理负数天/时/分）。

技术栈：Swift 6.0（`@MainActor`，Xcode 27 的 Swift 6 语言模式）+ AppKit + ScreenSaver.framework，部署目标 macOS 13.0，使用 Xcode 27 构建。

## 常用命令

没有测试 target，也没有 lint 配置。

本机 `xcode-select` 指向 CommandLineTools，直接跑 `xcodebuild` 会报 "requires Xcode"，需用 `DEVELOPER_DIR` 指定 Xcode：

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

# 构建 saver（产物在 build/Build/Products/Release/Countdown.saver）
xcodebuild -project Countdown.xcodeproj -scheme Countdown -configuration Release \
  -derivedDataPath build build

# 安装到系统可用的 saver 目录（安装后需重启 System Settings 才会刷新）
cp -R build/Build/Products/Release/Countdown.saver ~/Library/Screen\ Savers/

# 构建并运行 Preview App（用于在普通窗口里调试 saver，无需进系统偏好设置）
xcodebuild -project Countdown.xcodeproj -scheme Preview -configuration Debug \
  -derivedDataPath build build

# 查看可用的 scheme / target
xcodebuild -list -project Countdown.xcodeproj
```

一般开发流程用 Xcode 打开 `Countdown.xcodeproj`，选 Preview scheme 运行；只有在验证真实的 ScreenSaver 集成时，才构建 Countdown scheme 并把 `.saver` 安装到 `~/Library/Screen Savers/`。

## 架构

两个 target **共享同一批源文件**（`Countdown/Sources/*.swift` 同时编译进 Countdown 和 Preview 两个 target），差异只在入口：

- **Countdown**：`com.apple.product-type.bundle`，产物 `Countdown.saver`。`Info.plist` 的 `NSPrincipalClass` 指向 `Countdown.CountdownView`，由系统 screen saver 宿主实例化。
- **Preview**：普通 `.app`，`Preview/Sources/AppDelegate.swift` 以 `@main @MainActor` 标注并手动创建 `CountdownView` 塞进窗口，再用 `Timer` 以 `animationTimeInterval`（1/30 秒）手动调用 `ScreenSaverView.animateOneFrame()` —— 因为窗口模式下宿主不会自动驱动动画。修改 `CountdownView` 的动画逻辑后两个入口都要能不崩。

### 核心数据流

```
Configuration.xib (datePicker 绑定 Preferences.date)
        ↓ Cocoa Binding 写入
Preferences.date  →  ScreenSaverDefaults（key: "Date2"，存 timeIntervalSince1970）
        ↓ post Notification .dateDidChange
CountdownView.dateDidChange  →  重新读取 Preferences().date  →  didSet → updateFonts()
        ↓ 每帧 animateOneFrame()
Calendar.dateComponents([.day,.hour,.minute,.second], from: now, to: date)  → 四个 PlaceView
```

关键点：

- **Preferences 只在 init 时从 defaults 读一次**，之后靠 `.dateDidChange` 通知刷新。若新增配置项，必须沿用 `ScreenSaverDefaults` + 通知的模式，否则 saver 在运行中不会感知配置变化。
- `Preferences` 在 `Configuration.xib` 中是独立 customObject，通过 KVC binding（`keyPath="self.date"`）与 datePicker 双向绑定；因此 `date` 必须保持 `@objc`。
- 配置 UI 通过 `ScreenSaverView.hasConfigureSheet` / `configureSheet` 返回 `ConfigurationWindowController`（nib 名 `Configuration`）的 window。`ConfigurationWindowController.close(_:)` 仅关窗，不主动通知——靠 `Preferences.date` 的 setter 发通知。
- `date` 为 nil 时显示 `placeholderLabel`（提示去系统偏好设置选日期），否则显示 `placesView`（4 个 `PlaceView` 组成的 `NSStackView`）。

### 视图层

- `Label`：不可编辑、无边框、无背景的 `NSTextField` 薄封装，所有文本都走它。
- `PlaceView`：一个数值 + 一行副标题（DAYS/HOURS/MINUTES/SECONDS）的垂直组合视图，用 Auto Layout 约束拼装。
- `CountdownView`：负责布局与字号缩放。`updateFonts()` 以 `bounds.width` 为基准按比例计算字号（数字 `width/8`、副标题 `width/38`、占位符 `width/30`），并在 `resize(withOldSuperviewSize:)` 和 `viewDidMoveToSuperview()` 中重算——所以任何新的、尺寸相关的样式都必须放进 `updateFonts()`。数字字体通过 `NSFontDescriptor` 的 `kMonospacedNumbersSelector` 开启等宽数字特性，避免倒计时跳动。
- `draw(_:)` 只填充纯黑背景，无其他绘制。

## 注意事项

- 代码风格为 Tab 缩进，与现有文件保持一致。
- 签名配置为 Ad-hoc（`CODE_SIGN_IDENTITY = "-"`、`CODE_SIGN_STYLE = Manual`），已移除原作者 `DEVELOPMENT_TEAM`；不要改回自动签名，否则本机没有对应证书会直接构建失败。
- 打开系统偏好设置里的 Screen Saver 面板偶尔会缓存旧的 bundle，改动后需要退出并重开系统偏好设置才能看到新版本。
- 该项目使用 `Cocoa Binding` 与 `.xib`，不要用纯代码重写配置界面：`Configuration.xib` 同时被两个 target 打包。
- 升级到 Swift 6 后，`Preview` 的入口用 `@main` 取代了已废弃的 `@NSApplicationMain`，且必须在类型上标 `@MainActor`（`NSApplicationDelegate` 回调与 AppKit 视图都在主 actor）；新增的 AppKit 相关类型沿用同样标注。
