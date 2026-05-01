---
name: eyeguard-cli
description: 护眼卫士命令行工具 — 查看和控制 EyeGuard 状态栏计时器
platforms: [macos]
---

# eyeguard — 护眼卫士命令行工具

通过 `~/.eyeguard/bin/eyeguard` 或直接用项目里的 `eyeguard` 脚本控制护眼卫士 App。

## 命令

| 命令 | 说明 |
|------|------|
| `eyeguard status` | 查看当前状态（含剩余时间） |
| `eyeguard start` | 开始工作 |
| `eyeguard pause` | 暂停 |
| `eyeguard resume` | 继续（从暂停恢复） |
| `eyeguard toggle` | 暂停/继续切换 |
| `eyeguard reset` | 重置当前计时 |
| `eyeguard rest-now` | 立即进入休息 |
| `eyeguard skip` | 跳过休息（需处于休息中） |
| `eyeguard stats` | 今日统计（轮次+累计休息） |
| `eyeguard settings` | 查看当前所有配置 |
| `eyeguard set-style <name>` | 切换状态栏样式 |
| `eyeguard launch` | 启动 App |
| `eyeguard quit` | 退出 App |
| `eyeguard dim` | 暗屏（亮度=0%） |
| `eyeguard bright` | 亮屏（亮度=80%） |
| `eyeguard help` | 显示帮助 |

## 状态栏样式

共有 8 种样式，可用 `eyeguard set-style <name>` 切换：

| 名称 | 工作 Working | 暂停 Paused | 休息 Resting |
|------|------------|-----------|------------|
| `classic` | Working 29:59 | Paused 29:59 | Resting 29:59 |
| `minimal` | 29:59 | 29:59 | 29:59 |
| `emoji` | 💼 29:59 | ⏸ 29:59 | 🌿 29:59 |
| `compact` | W 29:59 | P 29:59 | R 29:59 |
| `bracket` | [工作中] 29:59 | [已暂停] 29:59 | [休息中] 29:59 |
| `star` | ☆工作中☆ 29:59 | ☆已暂停☆ 29:59 | ☆休息中☆ 29:59 |
| `dots` | ◐ 29:59 | ⏸ 29:59 | ◐ 29:59 |
| `progressBar` | ████░░░░ 29:59 | ⏸ 29:59 | ████░░░░ 29:59 |

空闲（idle）时，所有样式均显示为 `护眼卫士`。

### 样式说明

- **classic** — 英文单词开头，最通用的国际化风格
- **minimal** — 仅显示时间，极简主义
- **emoji** — 图标+时间，直观醒目
- **compact** — 单字母+时间，占用空间最小
- **bracket** — 方括号包裹中文状态，结构清晰
- **star** — 星标装饰，中文风格
- **dots** — 动态圆弧 ◐◔◑◕ 随进度旋转（暂停时固定为 ⏸）
- **progressBar** — 8格进度条 ██░░░░░░ 实时反映剩余时间

## 输出示例

```bash
$ eyeguard status
工作中 29:55

$ eyeguard stats
今日完成 3 轮，休息 15 分钟

$ eyeguard settings
工作时长:   30 分钟
休息时长:   5 分钟
强制休息:   开
锁屏暂停:   开
工作通知:   开
休息通知:   关
音效提示:   开
开机启动:   关
状态栏样式: classic

$ eyeguard set-style emoji
{"ok":true}
```

## 全局快捷键

| 快捷键 | 行为 |
|--------|------|
| `⌘⇧E` | 继续工作（从暂停恢复） |
| `⌘⇧P` | 暂停计时 |

## 技术细节

- **通信方式**：Unix Domain Socket（`/tmp/eyeguard.sock`）
- **前提条件**：EyeGuard App 必须在运行
- **CLI**：纯 shell 脚本 + `nc`（netcat）发送命令，JSON 解析支持 `jq` / Python / Perl 降级
- **App 端**：`SocketBridge.swift` 监听 socket 并转发给 `TimerManager`
- **Socket 超时**：2 秒（防止 nc 挂起）
