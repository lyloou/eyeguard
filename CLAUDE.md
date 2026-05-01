# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

EyeGuard (护眼卫士) is a macOS menu-bar app that enforces work/rest cycles (20-20-20 / Pomodoro style). It ships as an `.app` bundle + a shell CLI in **`scripts/eyeguard`** (installed to `~/.eyeguard/bin/eyeguard` via **`scripts/install.sh`** / the release zip flow) that talks to the app over a Unix Domain Socket.

## Build

Prerequisites: `brew install xcodegen`

```bash
# Regenerate .xcodeproj after editing project.yml
xcodegen generate

# Build release
xcodebuild -project EyeGuard.xcodeproj -scheme EyeGuard -configuration Release build \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO
```

Build output: `~/Library/Developer/Xcode/DerivedData/EyeGuard-*/Build/Products/Release/EyeGuard.app`

## Release

```bash
./scripts/release.sh <version>   # e.g. ./scripts/release.sh 0.1.9
# Auto-bumps patch from latest GitHub release if version omitted
```

The release script builds, then packs `Archive/v{X}.zip` with a **flat root**: `EyeGuard.app.zip`, `eyeguard`, `install.sh`, `skills/` (no `Release/` folder), then uploads via `gh release create`.

## Architecture

### State machine (`Sources/Core/StateMachine.swift`)

```
idle → working → resting → working (loop)
         ↕
       paused
```

`EyeState` is an enum: `.idle`, `.working`, `.paused(remaining:)`, `.resting`.

### Source layout

| Directory | Role |
|-----------|------|
| `Sources/Core/` | `TimerManager` (DispatchSourceTimer, 1 s ticks), `StateMachine`, `Settings` (UserDefaults), `StatsManager`, `L10n` |
| `Sources/UI/` | `StatusBarController` (NSStatusItem + menu), `RestWindowController` (NSPanel shown on rest), `SettingsWindowController`, `OnboardingWindowController`, `AboutWindowController` |
| `Sources/System/` | `SocketBridge` (Unix Domain Socket IPC), `LockScreenMonitor`, `HotkeyManager` (Carbon), `SoundManager` (AudioToolbox), `NotificationManager` |
| `scripts/` | `eyeguard` (shell CLI → `/tmp/eyeguard.sock`), `install.sh` (packaged flat into `v{X}.zip` root), `release.sh`, `restart.sh` |

### CLI ↔ App IPC

The shell CLI (`eyeguard`) sends newline-terminated text commands to `/tmp/eyeguard.sock` and receives JSON back. `SocketBridge.swift` listens on that socket and dispatches to `TimerManager`. Single-instance lock uses `flock` on `/tmp/eyeguard.lock`.

### Key wiring in `AppDelegate`

`AppDelegate` owns all long-lived managers. Startup order matters: `StatusBarController` → `LockScreenMonitor` → `SocketBridge` → `HotkeyManager` → `TimerManager`. `TimerManager` holds a weak ref to `StatusBarController` for UI updates.

### project.yml (XcodeGen)

Edit `project.yml` to change build settings, add files, or update the deployment target (currently macOS 12.0). Run `xcodegen generate` after any change.

## Dev Workflow

### 日常开发重启

```bash
./scripts/restart.sh
```

脚本会自动：`xcodegen generate` → `xcodebuild Debug` → 杀旧进程 → 启动新 build。

**不要**手动跑 `xcodebuild` 来验证，要用 `restart.sh`——它的错误检测用 `grep " error:"` 匹配 xcodebuild 的实际格式（`path:line: error: ...`），而不是行首 `^error:`。

### 新增源文件后必须重新生成 xcodeproj

XcodeGen 只在显式执行时更新 `.xcodeproj`，新建的 `.swift` 文件不会自动加入编译。`restart.sh` 已在编译前自动跑 `xcodegen generate`，但手动 `xcodebuild` 时需先手动执行：

```bash
xcodegen generate
```

### SourceKit 跨文件错误是假阳性

IDE 里显示的 "Cannot find type X in scope" 等错误通常是 SourceKit 无法跨文件解析造成的，不影响 Xcode/xcodebuild 实际编译。以 `restart.sh` 的编译结果为准。

## UI 窗口开发规范

### `.accessory` 模式下的键盘响应

EyeGuard 使用 `NSApplication.activationPolicy(.accessory)`（无 Dock 图标）。在这个模式下，普通 `NSWindow` 在失去焦点后无法可靠地恢复键盘响应，需要：

1. 使用 `NSPanel` 子类（参见 `Sources/UI/AppPanel.swift`）
2. 重写 `canBecomeKey` 返回 `true`
3. 在 `mouseDown` 里显式调用 `NSApp.activate(ignoringOtherApps: true)` + `makeKeyAndOrderFront(nil)`
4. 设置 `becomesKeyOnlyIfNeeded = false`、`hidesOnDeactivate = false`
5. `show()` 时调用 `NSApp.activate(ignoringOtherApps: true)`

所有需要响应 ⌘W / ⌘Q 的窗口（Settings、About、Rest）均继承自 `AppPanel`。

### Local Monitor 键盘拦截

用 `NSEvent.addLocalMonitorForEvents(matching: .keyDown)` 拦截键盘事件，必须在窗口 `show()` 时安装、`windowWillClose` 时移除，防止泄漏。

```swift
// ⌘W 关窗，⌘Q 退出
keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
    guard event.modifierFlags.contains(.command) else { return event }
    switch event.keyCode {
    case 13: self.window?.close(); return nil   // ⌘W
    case 12: NSApp.terminate(nil); return nil   // ⌘Q
    default: return event
    }
}
```

`NSWindowController` 的 delegate 方法（如 `windowWillClose`）**不要加 `override`**，否则编译报错。

### 明暗主题适配

所有颜色通过 `ThemeColor`（`Sources/Core/ThemeColor.swift`）定义动态色，用 `NSColor(name:dynamicProvider:)` 实现自动适配，无需监听主题切换通知。

## CLI Commands

```bash
eyeguard status / start / pause / resume / reset / rest-now / skip / toggle
eyeguard stats / settings / set-style <name>
eyeguard dim / bright / launch / quit
```

## Skills

`skills/eyeguard-cli/` is bundled into every release zip alongside `EyeGuard.app.zip`, `install.sh`, and `eyeguard` at the archive root.
