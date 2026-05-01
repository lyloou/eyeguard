# EyeGuard 护眼卫士 — Release

## 目录结构

```
EyeGuard.app.zip/  macOS App（解压后安装）
eyeguard           命令行工具（位于项目根目录）
README.md          本文件
```

## 安装

### App
1. 解压 `EyeGuard.app.zip`
2. 拷贝 `EyeGuard.app` 到 `/Applications/`

### CLI（可选）
```bash
mkdir -p ~/.eyeguard/bin
cp eyeguard ~/.eyeguard/bin/
chmod +x ~/.eyeguard/bin/eyeguard
echo 'export PATH="$HOME/.eyeguard/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## 快捷键

| 按键 | 行为 |
|------|------|
| ⌘⇧E | 继续工作 |
| ⌘⇧P | 暂停计时 |

## CLI 命令

```bash
eyeguard status      # 查看状态
eyeguard start       # 开始工作
eyeguard pause       # 暂停
eyeguard resume      # 继续
eyeguard reset       # 重置
eyeguard rest-now    # 立即休息
eyeguard skip        # 跳过休息
eyeguard stats       # 今日统计
eyeguard settings    # 查看配置
eyeguard set-style <name>  # 切换样式
eyeguard launch      # 启动 App
eyeguard quit        # 退出 App
eyeguard dim         # 暗屏
eyeguard bright      # 亮屏
```

## 状态栏样式

classic | minimal | emoji | compact | bracket | star | dots | progressBar

---
Built: 2026-05-01 12:14:07
