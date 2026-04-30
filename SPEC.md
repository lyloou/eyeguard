# 护眼卫士 EyeGuard — 需求规格文档 v0.1

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
⚙ 设置...
─────────────────
❌ 退出
```

### 3.2 键盘快捷键

| 按键 | 场景 | 行为 |
|---|---|---|
| `Space` / `ESC` | 休息弹窗存在 | 关闭弹窗，开始工作计时 |
| `Space` / `ESC` | 其他状态 | 无操作 |

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

### 4.2 休息弹窗（NSPanel）

- **位置**：屏幕右上角（多屏跟随鼠标所在屏幕）
- **样式**：无标题栏、圆角、置顶、半透明背景
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

---

## 六、技术栈

| 模块 | 技术 |
|---|---|
| 框架 | 纯 AppKit |
| 定时器 | DispatchSourceTimer |
| 配置存储 | UserDefaults |
| 项目生成 | XcodeGen |
| 最低 macOS | 12.0+ |

### 6.1 架构 — Unix Domain Socket IPC

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
- **CLI 二进制**：`~/.hermes/bin/eyeguard`（纯 shell + netcat）

---

## 七、交付清单

- [x] 需求规格文档（本文）
- [x] Xcode 项目（XcodeGen 生成）—— `EyeGuard.xcodeproj`
- [x] 状态栏菜单（NSStatusItem）
- [x] 定时器核心（TimerManager + StateMachine）
- [x] 休息弹窗（NSPanel）
- [x] 锁屏检测（LockScreenMonitor）
- [x] 设置面板（设置窗口 + UserDefaults）
- [x] 单例保护（/tmp/eyeguard.lock）
- [x] Unix Domain Socket IPC（SocketBridge.swift）
- [x] CLI 工具（~/.hermes/bin/eyeguard + skill）
- [x] 构建验证（编译通过 ✅）
