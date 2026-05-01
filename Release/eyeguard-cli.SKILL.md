---
name: eyeguard-cli
description: 护眼卫士命令行工具 — 查看和控制 EyeGuard 状态栏计时器
platforms: [macos]
prerequisites:
  binaries:
    - path: ~/.hermes/bin/eyeguard
      note: EyeGuard App 端通过 Unix Domain Socket /tmp/eyeguard.sock 接收命令，App 必须在运行
---

# eyeguard — 护眼卫士命令行工具

通过 `~/.hermes/bin/eyeguard` 控制护眼卫士 App，支持以下命令：

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
| `eyeguard set-style <name>` | 切换状态栏样式（classic/minimal/emoji/compact/bracket/star/pureTime/dots/progressBar） |
| `eyeguard dim` | 暗屏（亮度=0%） |
| `eyeguard bright` | 亮屏（亮度=80%） |
| `eyeguard help` | 显示帮助 |

## 输出示例

```bash
# 查看状态（CLI 自动格式化中文）
$ eyeguard status
工作中 29:55

# 今日统计
$ eyeguard stats
今日完成 3 轮，休息 15 分钟

# 查看完整配置
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

# 直接透传的命令（返回 JSON）
$ eyeguard start
{"ok":true}
```

## 全局快捷键

App 还支持全局快捷键（在任意应用中可用）：

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
