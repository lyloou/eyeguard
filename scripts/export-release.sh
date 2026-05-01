#!/bin/bash
# export-release.sh — 导出 EyeGuard 发布产物到 Release/
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RELEASE_DIR="$PROJECT_DIR/Release"
CLI_SRC="$PROJECT_DIR/eyeguard"
BUILD_DATE="$(date +"%Y-%m-%d %H:%M:%S")"

# ── 0. Save CLI path before cleaning ─────────────────────────
CLI_BACKUP="/tmp/eyeguard_cli_backup"
if [[ -f "$CLI_SRC" ]]; then
    cp "$CLI_SRC" "$CLI_BACKUP"
fi

# ── 1. Clean & Build ───────────────────────────────────────
echo "==> Clean Release/"
rm -rf "$RELEASE_DIR"/*
mkdir -p "$RELEASE_DIR"

echo "==> Building EyeGuard.app..."
cd "$PROJECT_DIR"
xcodebuild -project EyeGuard.xcodeproj -scheme EyeGuard -configuration Release build \
    CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO > /dev/null 2>&1

APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/EyeGuard-* -name "EyeGuard.app" -type d 2>/dev/null | grep -v "Intermediate" | head -1)
if [[ -z "$APP_PATH" ]] || [[ ! -d "$APP_PATH" ]]; then
    echo "Error: EyeGuard.app not found after build"
    exit 1
fi
echo "    Found: $APP_PATH"
cp -R "$APP_PATH" "$RELEASE_DIR/EyeGuard.app"
echo "    Copied to $RELEASE_DIR/EyeGuard.app"

# ── 2. Copy CLI ─────────────────────────────────────────────
if [[ -f "$CLI_BACKUP" ]]; then
    echo "==> Copying eyeguard CLI..."
    cp "$CLI_BACKUP" "$RELEASE_DIR/eyeguard"
    chmod +x "$RELEASE_DIR/eyeguard"
    echo "    Copied to $RELEASE_DIR/eyeguard"
    rm -f "$CLI_BACKUP"
fi

# ── 3. Compress App ────────────────────────────────────────
echo "==> Compressing EyeGuard.app..."
(cd "$RELEASE_DIR" && zip -r "EyeGuard.app.zip" "EyeGuard.app" -x "*.DS_Store" && rm -rf "EyeGuard.app")
echo "    Created EyeGuard.app.zip"

# ── 4. Generate README ─────────────────────────────────────
echo "==> Generating README..."
cat > "$RELEASE_DIR/README.md" << 'README_EOF'
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
Built: BUILD_DATE_PLACEHOLDER
README_EOF

# 替换 BUILD_DATE_PLACEHOLDER 为实际日期
sed -i '' "s/BUILD_DATE_PLACEHOLDER/$BUILD_DATE/g" "$RELEASE_DIR/README.md"

echo ""
echo "==> Done. Release/ contents:"
ls -lh "$RELEASE_DIR"
