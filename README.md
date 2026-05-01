# EyeGuard 护眼卫士

![Latest Release](https://img.shields.io/github/v/release/lyloou/eyeguard?color=green&label=Latest)


macOS 菜单栏倒计时工具。工作 30 分钟 → 休息 5 分钟，循环往复，守护视力。

无 Dock 图标，运行在状态栏，轻量安静。

---

## 功能一览

| 功能 | 说明 |
|------|------|
| 状态栏倒计时 | `工作中 29:59` / `休息中 04:59` / `已暂停 15:23` |
| 状态栏样式 | 8种可选，颜色各异（工作中默认色/暂停黄色/休息绿色） |
| 自动循环 | 工作结束 → 弹窗提醒休息 → 休息结束 → 自动开始下一轮 |
| 暂停 / 继续 | 随时暂停计时，保留剩余时间 |
| 锁屏自动暂停 | Mac 锁屏时自动冻结计时，解锁后继续 |
| 跳过休息 | 非强制模式下可提前跳过休息 |
| 命令行控制 | `eyeguard status` / `start` / `pause` / `reset` 等 |
| 设置面板 | 可配置工作/休息时长、强制模式、锁屏暂停等 |
| 音效提示 | 工作/休息开始时播放系统音效 |
| 全局快捷键 | `⌘⇧E` 继续工作 / `⌘⇧P` 暂停 |
| 登录启动 | 开机自动运行（SMAppService） |
| 今日统计 | 菜单底部显示今日轮次和累计休息时长 |
| 国际化 | 中文 / English |
| 首次引导 | 首次启动时 3 步引导介绍 |
| 暗黑适配 | 深浅色模式自动适配 |

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
🌑 暗屏
☀️ 亮屏
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

### 全局快捷键

在任意应用中均可使用：

| 快捷键 | 行为 |
|--------|------|
| `⌘⇧E` | 继续工作（从暂停恢复）|
| `⌘⇧P` | 暂停计时 |

### 命令行

```bash
~/.eyeguard/bin/eyeguard status      # 查看当前状态
~/.eyeguard/bin/eyeguard start      # 开始工作
~/.eyeguard/bin/eyeguard pause      # 暂停
~/.eyeguard/bin/eyeguard resume     # 继续
~/.eyeguard/bin/eyeguard reset      # 重置当前计时
~/.eyeguard/bin/eyeguard rest-now   # 立即进入休息
~/.eyeguard/bin/eyeguard skip       # 跳过休息
~/.eyeguard/bin/eyeguard settings   # 查看配置
```

### AI Agent Skill（可选）

与 CLI 配套的 Agent Skill 放在 **`skills/eyeguard-cli/`** 目录下（内含 **`SKILL.md`**），命名与目录约定与常见的 skills 合集一致（例如 [JimLiu/baoyu-skills — README](https://github.com/JimLiu/baoyu-skills/blob/main/README.md) 中的 `skills/baoyu-*` 一类结构：`skills/<skill-name>/`）。

**在助手 / IDE 中使用：**

1. **克隆本仓库**：将 `skills/eyeguard-cli` 整个文件夹复制或符号链接到你的客户端所要求的 Skill 加载目录（详见 Cursor、Claude Code 等各自的 Skill / 插件说明）。
2. **从 Release 安装包取用**：解压 `v{x.x.x}.zip` 后，在解压目录中会看到 **`skills/eyeguard-cli/SKILL.md`**，可把该文件夹按同样方式挂载到 Skill 仓库或本地 skills 路径。

Skill 前置元数据：`name` 为 `eyeguard-cli`，`platforms` 含 `macos`。完整子命令表见 [skills/eyeguard-cli/SKILL.md](skills/eyeguard-cli/SKILL.md)。

### 设置项

| 配置 | 默认值 | 说明 |
|------|--------|------|
| 工作时长 | 30 min | 范围 1~120 分钟 |
| 休息时长 | 5 min | 范围 1~30 分钟 |
| 强制休息 | 开 | 关闭后可跳过休息 |
| 锁屏暂停 | 开 | 锁屏自动冻结计时 |
| 工作结束通知 | 开 | 工作结束时发送系统通知 |
| 休息结束通知 | 关 | 休息结束时发送系统通知 |
| 音效提示 | 开 | 工作/休息开始时播放音效 |
| 开机自动启动 | 关 | 登录时自动运行 |
| 状态栏样式 | classic | 8种可选：classic / minimal / emoji / compact / bracket / star / dots / progressBar |

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
│  StateMachine: idle / working / paused / resting   │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│  RestWindowController — 休息弹窗（NSPanel）           │
│  NSVisualEffectView 暗黑适配                         │
│  LockScreenMonitor — 锁屏检测                        │
│  HotkeyManager — 全局快捷键（Carbon）                │
│  LoginItemManager — 登录启动（SMAppService）        │
│  SoundManager — 音效提示（AudioToolbox）             │
│  StatsManager — 今日统计                             │
│  Settings — UserDefaults 持久化                       │
│  SocketBridge — Unix Domain Socket（接收 CLI）        │
│  L10n — 国际化                                      │
└─────────────────────────────────────────────────────┘

CLI (shell + nc)                              App
     │ nc -U /tmp/eyeguard.sock              │
     ├──────────────────────────────────────► SocketBridge.swift
     │                                        (TimerManager)
     │ ◄── JSON 响应 ─────────────────────────┘
```

- **Socket**：`/tmp/eyeguard.sock`
- **单例锁**：`/tmp/eyeguard.lock`（flock）
- **CLI 二进制**：`~/.eyeguard/bin/eyeguard`

### 目录结构

```
Sources/
├── main.swift                      # 入口，单例检测
├── AppDelegate.swift               # 应用生命周期
├── Core/
│   ├── TimerManager.swift          # 定时器核心
│   ├── StateMachine.swift           # 状态定义
│   ├── Settings.swift               # UserDefaults 配置
│   ├── StatsManager.swift           # 今日统计
│   └── L10n.swift                   # 国际化字符串
├── UI/
│   ├── StatusBarController.swift     # 状态栏
│   ├── RestWindowController.swift    # 休息弹窗
│   ├── SettingsWindowController.swift # 设置窗口
│   ├── OnboardingWindowController.swift # 首次引导
│   └── AboutWindowController.swift   # 关于窗口
└── System/
    ├── LockScreenMonitor.swift      # 锁屏检测
    ├── SocketBridge.swift           # Socket IPC
    ├── HotkeyManager.swift          # 全局快捷键
    ├── LoginItemManager.swift       # 登录启动
    ├── SoundManager.swift           # 音效
    └── NotificationManager.swift    # 系统通知
```

---

## 安装

### 一键安装（推荐）

```bash
# 方式一：自动获取最新版
curl -fsSL https://raw.githubusercontent.com/lyloou/eyeguard/main/install.sh | bash

# 方式二：指定版本
curl -fsSL https://raw.githubusercontent.com/lyloou/eyeguard/main/install.sh | bash -s -- 0.1.8
```

然后运行 `source ~/.zshrc`，输入 `eyeguard status` 验证。

### 手动安装

1. 下载 [最新 Release](https://github.com/lyloou/eyeguard/releases/latest)
2. 解压 `v{x.x.x}.zip`，将 `Release/EyeGuard.app` 拷贝到 `/Applications/`
3. （可选）将 `Release/eyeguard` 拷贝到 `~/.eyeguard/bin/eyeguard`，并确认 PATH 包含该目录

## 构建（开发者）

### 前置依赖

- macOS 12.0+
- XcodeGen：`brew install xcodegen`

### 构建

```bash
cd eyeguard
xcodegen generate
xcodebuild -project EyeGuard.xcodeproj -scheme EyeGuard -configuration Release build
```

产物：`~/Library/Developer/Xcode/DerivedData/EyeGuard-*/Build/Products/Release/EyeGuard.app`

### 发布

```bash
./scripts/release.sh <version>   # 例如：./scripts/release.sh 0.1.5
```

发布产物 `Archive/v{x.x.x}.zip` 内包含 `Release/`、`install.sh` 以及 **`skills/eyeguard-cli/`**（供 Agent Skill 使用）。

---

## 相关文档

- [SPEC.md](SPEC.md) — 完整需求规格
- [skills/eyeguard-cli/SKILL.md](skills/eyeguard-cli/SKILL.md) — Agent Skill / `eyeguard` CLI 参考
