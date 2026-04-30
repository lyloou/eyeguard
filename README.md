# EyeGuard 护眼卫士

macOS 菜单栏倒计时工具。工作 30 分钟 → 休息 5 分钟，循环往复，守护视力。

无 Dock 图标，运行在状态栏，轻量安静。

---

## 功能概览

| 功能 | 说明 |
|------|------|
| 状态栏倒计时 | `工作中 29:59` / `休息中 04:59` / `已暂停 15:23` |
| 自动循环 | 工作结束 → 弹窗提醒休息 → 休息结束 → 自动开始下一轮 |
| 暂停 / 继续 | 随时暂停计时，保留剩余时间 |
| 锁屏自动暂停 | Mac 锁屏时自动冻结计时，解锁后继续 |
| 跳过休息 | 非强制模式下可提前跳过休息 |
| 命令行控制 | `eyeguard status` / `start` / `pause` / `reset` 等 |
| 设置面板 | 可配置工作/休息时长、强制模式、锁屏暂停 |

---

## 状态机

```
空闲
  │
  │ 开始
  ▼
工作中 ──→ 已暂停 ──→ 工作中
  │                        ▲
  │ 计时归零               │
  ▼                        │
休息中 ─────────────────────┘
  │ (按 Space/ESC 或计时结束)
  ▼
下一轮工作
```

---

## 使用

### 菜单栏交互

左键点击状态栏图标打开菜单：

```
当前状态: 工作中 29:59
─────────────────
▶ 开始          （空闲时可见）
⏸ 暂停          （工作中可见）
🔄 重置
⏰ 立即休息
─────────────────
⚙ 设置...
─────────────────
❌ 退出
```

### 命令行

```bash
~/.hermes/bin/eyeguard status      # 查看当前状态
~/.hermes/bin/eyeguard start      # 开始工作
~/.hermes/bin/eyeguard pause      # 暂停
~/.hermes/bin/eyeguard resume     # 继续
~/.hermes/bin/eyeguard reset      # 重置当前计时
~/.hermes/bin/eyeguard rest-now   # 立即进入休息
~/.hermes/bin/eyeguard skip       # 跳过休息
~/.hermes/bin/eyeguard settings   # 查看配置
```

### 设置项

| 配置 | 默认值 | 说明 |
|------|--------|------|
| 工作时长 | 30 min | 范围 1~120 分钟 |
| 休息时长 | 5 min | 范围 1~30 分钟 |
| 强制休息 | 开 | 关闭后可跳过休息 |
| 锁屏暂停 | 开 | 锁屏自动冻结计时 |

---

## 技术架构

```
┌─────────────────────────────────────────────────────┐
│  macOS Menu Bar (NSStatusItem)                     │
│  StatusBarController — 状态栏文字 + 下拉菜单        │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│  TimerManager — 定时器核心                          │
│  DispatchSourceTimer 精确计时                       │
│  状态机：idle / working / paused / resting         │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│  RestWindowController — 休息弹窗（NSPanel）         │
│  LockScreenMonitor — 锁屏检测                       │
│  Settings — UserDefaults 持久化                     │
│  SocketBridge — Unix Domain Socket（接收 CLI）      │
└─────────────────────────────────────────────────────┘

CLI (shell + nc)                              App
      │ nc -U /tmp/eyeguard.sock              │
      ├──────────────────────────────────────► SocketBridge.swift
      │                                        (TimerManager)
      │ ◄── JSON 响应 ─────────────────────────┘
```

- **Socket**：`/tmp/eyeguard.sock`
- **单例锁**：`/tmp/eyeguard.lock`（flock）
- **CLI 二进制**：`~/.hermes/bin/eyeguard`

### 目录结构

```
Sources/
├── main.swift              # 入口，单例检测
├── AppDelegate.swift       # 应用生命周期
├── Core/
│   ├── TimerManager.swift  # 定时器核心
│   ├── StateMachine.swift   # 状态定义
│   └── Settings.swift       # UserDefaults 配置
├── UI/
│   ├── StatusBarController.swift   # 状态栏
│   ├── RestWindowController.swift   # 休息弹窗
│   └── SettingsWindowController.swift # 设置窗口
└── System/
    ├── LockScreenMonitor.swift # 锁屏检测
    └── SocketBridge.swift     # Socket IPC
```

---

## 安装 / 构建

### 前置依赖

- macOS 12.0+
- XcodeGen：`brew install xcodegen`

### 构建

```bash
cd /Users/lilou/t/eyefoocopy
xcodegen generate
xcodebuild -project EyeGuard.xcodeproj -scheme EyeGuard -configuration Release build
```

产物：`~/Library/Developer/Xcode/DerivedData/EyeGuard-*/Build/Products/Release/EyeGuard.app`

### 首次运行后，CLI 即可使用

```bash
~/.hermes/bin/eyeguard status
```

---

## 相关文档

- [SPEC.md](SPEC.md) — 完整需求规格
- [eyeguard-cli skill](../productivity/eyeguard-cli/SKILL.md) — 命令行工具详情
