# 护眼卫士 EyeGuard — 需求规格文档 v0.2

## 一、项目概述

**项目名称**: EyeGuard（护眼卫士）
**类型**: macOS 菜单栏工具（无 Dock 图标）
**一句话描述**: 状态栏数字倒计时，工作30分钟 → 弹窗休息5分钟 → 按空格/ESC重新开始

---

## 二、状态机

```
空闲 ←──────────────────────────────┐
  │                                  │
  │ 开始                             │
  ▼                                  │
工作中 ──→ 已暂停 ──→ 工作中 ←───┤  (休息结束+按键)
  │                                  │  (或提前结束休息)
  │ 计时归零                         │
  ▼                                  │
休息中 ───────────────────────────────┘
  │ (按Space/ESC)
  │ (或计时归零后自动弹出，按键触发)
  ▼
下一轮工作
```

### 状态定义

| 状态 | 触发条件 | 状态栏显示 | 可用操作 |
|---|---|---|---|
| **空闲** | App启动（默认） | `护眼卫士` | 开始 |
| **工作中** | App启动（自动） | `工作中 29:59` | 暂停 / 重置 |
| **工作中** | 点击「开始」| `工作中 29:59` | 暂停 / 重置 |
| **已暂停** | 计时中点「暂停」| `已暂停 15:23`（冻结值）| 继续 / 重置 |
| **休息中** | 工作计时归零 | `休息中 04:59` | 跳过（可配置） |
| **空闲** | 休息计时归零后按Space/ESC | `护眼卫士` | 开始 |

---

## 三、交互规则

### 3.1 状态栏菜单（左键点击 NSStatusItem）

```
当前状态: 工作中 29:59
─────────────────
▶ 开始
⏸ 暂停
🔄 重置
─────────────────
  今日统计
  3 轮已完成
  15 分钟休息
─────────────────
⚙ 设置...
关于 EyeGuard
─────────────────
❌ 退出
```

### 3.2 键盘快捷键

| 按键 | 场景 | 行为 |
|---|---|---|
| `Space` / `ESC` | 休息弹窗存在 | 关闭弹窗，开始工作计时 |
| `Space` / `ESC` | 其他场景 | 无操作 |
| `⌘⇧P`（默认，可改） | 全局 | **计时**：空闲开始；工作中暂停；已暂停继续（休息中不响应） |
| `⌘⇧X`（默认，可改） | 全局 | 立即休息（工作中或已暂停） |

### 3.3 暂停/重置

- **暂停**：计时冻结，显示冻结值
- **继续**：从冻结时间恢复
- **重置**：回到当前状态初始值（工作中→30min，休息中→5min）

### 3.4 休息弹窗规则

- **触发时机**：只有「休息中」才显示弹窗
- **关闭后**：立即开始工作计时（无延迟）
- **强制模式（默认）**：无跳过按钮，必须等计时结束，按 Space/ESC 开始工作
- **非强制模式**：显示 [跳过休息] 按钮，用户可提前结束

---

## 四、UI 设计

### 4.1 状态栏

- `NSStatusItem`，左键点击显示下拉菜单
- 状态文字格式：`{状态名} {MM:SS}` 或 `{状态名}`
- 无图标，纯文字显示，颜色跟随状态变化

### 4.2 休息弹窗（NSPanel）

- **位置**：屏幕右上角（多屏跟随鼠标所在屏幕）
- **样式**：无标题栏、圆角、置顶、`NSVisualEffectView`（自适应深浅色）
- **内容**：
  - 主文本：`休息中` 或 `Resting`
  - 倒计时：`04:59`（大字）
  - 跳过按钮（非强制模式）：`跳过休息`
- **关闭方式**：按 Space / ESC / 点击跳过按钮
- **禁止关闭**：强制模式下计时未到不能关闭

### 4.3 设置面板

可配置项（`UserDefaults` 持久化）：

| 配置项 | 默认值 | 说明 |
|---|---|---|
| `workDuration` | 30 min | 工作时长，范围 1~120 |
| `restDuration` | 5 min | 休息时长，范围 1~30 |
| `enforceRest` | true | 强制休息（不允许跳过） |
| `pauseOnLock` | true | 锁屏自动暂停 |
| `notifyOnWorkEnd` | true | 工作结束时发送通知 |
| `notifyOnRestEnd` | false | 休息结束时发送通知 |
| `soundEnabled` | true | 音效提示 |
| `launchAtLogin` | false | 开机自动启动 |
| `statusBarStyle` | classic | 状态栏文字样式（8种可选） |
| `globalHotkeyToggleEnabled` 等 | 见代码 | 全局快捷键：计时 / 立即休息（默认 ⌘⇧P、⌘⇧X，可改可清除） |

### 状态栏样式

支持 8 种文字样式，切换实时生效。状态栏文字带颜色：

| 样式 | 工作中 | 已暂停 | 休息中 |
|---|---|---|---|
| `classic` | Working 29:59 | Paused 15:23 | Resting 04:59 |
| `minimal` | 工作中 29:59 | 已暂停 15:23 | 休息中 04:59 |
| `emoji` | 💼工作中 29:59 | ⏸已暂停 15:23 | 🌿休息中 04:59 |
| `compact` | W 29:59 | P 15:23 | R 04:59 |
| `bracket` | [工作中] 29:59 | [已暂停] 15:23 | [休息中] 04:59 |
| `star` | ☆工作中☆ 29:59 | ☆已暂停☆ 15:23 | ☆休息中☆ 04:59 |
| `dots` | ◐工作中 29:59 | ⏸ 15:23 | ◑休息中 04:59 |
| `progressBar` | ████░░░░ 29:59 | ⏸ 15:23 | ██░░░░░░ 04:59 |

**状态栏文字颜色规则：**

| 状态 | 颜色 | 说明 |
|---|---|---|
| 工作中 / 空闲 | 系统默认文字色 | `.labelColor`，自适应深浅色 |
| 已暂停 | 🟡 黄色 `.systemYellow` | 醒目提示暂停状态 |
| 休息中 | 🟢 绿色 `.systemGreen` | 放松、休息暗示 |

使用 `NSAttributedString` 实现，颜色跟随系统深浅色模式自适应。

---

## 五、系统集成

### 5.1 锁屏检测

监听以下任一事件触发暂停：
- `NSWorkspace.sessionDidResignActiveNotification`
- `DistributedNotificationCenter` 监听 `com.apple.screenIsLocked`

解锁后自动恢复计时。

### 5.2 单例

启动时检测是否已有实例运行，有则退出。

### 5.3 菜单栏 App

`NSApplication.setActivationPolicy(.accessory)` — 隐藏 Dock 图标。

### 5.4 系统通知

使用 `UserNotifications.framework`，支持工作结束/休息结束时发送本地通知：

| 通知 | 默认 | 触发时机 |
|------|------|---------|
| 工作结束提醒 | ✅ 开启 | `startResting()` 时 |
| 休息结束提醒 | ❌ 关闭 | `dismissRestWindow()` / `restTimerExpired()` 时 |

- 通知点击后聚焦 App 窗口
- 首次启动时请求通知授权（`UNUserNotificationCenter`）

### 5.5 音效提示

使用 `AudioToolbox` 系统音效 ID：

| 事件 | 音效 |
|------|------|
| 工作结束（开始休息） | `kSystemSoundID_1016`（Basso）|
| 休息结束（开始工作） | `kSystemSoundID_1013`（Pop）|

### 5.6 登录启动

使用 `SMAppService`（macOS 13+）注册/取消登录项。

### 5.7 全局快捷键

使用 Carbon `RegisterEventHotKey` API，组合键存于 UserDefaults，可在设置面板录制或清除。

| 快捷键（默认） | 行为 |
|----------------|------|
| `⌘⇧P` | **计时**：空闲开始；工作中暂停；已暂停继续（休息中不响应） |
| `⌘⇧X` | 立即休息（工作中或已暂停） |

### 5.8 暗黑适配

- 休息弹窗使用 `NSVisualEffectView`（`.hudWindow` 材质）自动适配深浅色
- 状态栏图标使用 SF Symbol template image（`NSImageNameStatusBarIcon`）

---

## 六、今日统计

内存记录，`StatsManager` 管理，次日零时自动清零：

| 指标 | 说明 |
|------|------|
| `roundsCompletedToday` | 今日完成的轮次（每次工作→休息算1轮）|
| `totalRestMinutesToday` | 今日累计休息分钟数 |

菜单位置底部显示，格式：
```
  今日统计
  3 轮已完成
  15 分钟休息
```

---

## 七、国际化

`L10n.swift` 统一管理，`en.lproj/Localizable.strings` 提供英文：

| Key | 中文 | 英文 |
|-----|------|------|
| `appName` | 护眼卫士 | EyeGuard |
| `working` | 工作中 | Working |
| `resting` | 休息中 | Resting |
| `paused` | 已暂停 | Paused |
| `idle` | 空闲 | Idle |
| `menuStart` | ▶ 开始 | ▶ Start |
| `menuPause` | ⏸ 暂停 | ⏸ Pause |
| `settingsTitle` | 护眼卫士 设置 | EyeGuard Settings |
| `restTitle` | 休息一下 | Take a Break |
| ... | ... | ... |

---

## 八、首次引导

首次启动时自动弹出 3 步引导页：

1. 工作 30 分钟 → 休息 5 分钟
2. 休息弹窗出现时，按 Space/ESC 或等待
3. 自动开始下一轮

`Settings.hasLaunchedBefore` 判断，AppDelegate 在 `applicationDidFinishLaunching` 时检测。

---

## 九、技术栈

| 模块 | 技术 |
|---|---|
| 框架 | 纯 AppKit |
| 定时器 | DispatchSourceTimer |
| 配置存储 | UserDefaults |
| 项目生成 | XcodeGen |
| 最低 macOS | 12.0+ |

### 9.1 架构 — Unix Domain Socket IPC

```
CLI (shell + nc)                  App (Swift)
      │                                │
      │  nc -U /tmp/eyeguard.sock      │
      ├────────────────────────────────► SocketBridge.swift
      │                                │  (监听 socket)
      │                                ▼
      │                         TimerManager
      │                                │
      │  ◄── JSON 响应 ────────────────┤
```

- **Socket 路径**：`/tmp/eyeguard.sock`
- **协议**：JSON over Unix Domain Socket（行分隔）
- **单实例锁**：`/tmp/eyeguard.lock`（flock）
- **CLI 二进制**：`~/.eyeguard/bin/eyeguard`（纯 shell + netcat）；仓库源码为 **`scripts/eyeguard`**

---

## 十、交付清单

- [x] 需求规格文档（本文）
- [x] Xcode 项目（XcodeGen 生成）—— `EyeGuard.xcodeproj`
- [x] 状态栏菜单（NSStatusItem + SF Symbol template image）
- [x] 定时器核心（TimerManager + StateMachine + DispatchSourceTimer）
- [x] 休息弹窗（NSPanel + NSVisualEffectView 暗黑适配）
- [x] 锁屏检测（LockScreenMonitor）
- [x] 设置面板（SettingsWindowController + UserDefaults）
- [x] 单例保护（/tmp/eyeguard.lock）
- [x] Unix Domain Socket IPC（SocketBridge.swift）
- [x] CLI 工具（~/.eyeguard/bin/eyeguard + skill）
- [x] 系统通知（NotificationManager + UNUserNotificationCenter）
- [x] 音效提示（SoundManager + AudioToolbox）
- [x] 登录启动（LoginItemManager + SMAppService）
- [x] 全局快捷键（HotkeyManager + Carbon API）
- [x] 今日统计（StatsManager + 菜单底部显示）
- [x] 国际化（L10n.swift + en.lproj/Localizable.strings）
- [x] 首次引导（OnboardingWindowController）
- [x] 关于窗口（AboutWindowController）
- [x] App 图标（AppIcon.appiconset，绿色护眼主题）
- [x] 构建验证（编译通过 ✅）
