#!/bin/bash
# export-release.sh — 导出 EyeGuard 发布产物到 Release/
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RELEASE_DIR="$PROJECT_DIR/Release"
CLI_SRC="$HOME/.hermes/bin/eyeguard"
SKILL_SRC="$HOME/.hermes/skills/productivity/eyeguard-cli/SKILL.md"
BUILD_DATE="$(date +"%Y-%m-%d %H:%M:%S")"

echo "==> Clean Release/"
mkdir -p "$RELEASE_DIR"
rm -rf "$RELEASE_DIR"/*

# 1. Build App
echo "==> Building EyeGuard.app..."
APP_PATH=$(cd "$PROJECT_DIR" && xcodebuild -project EyeGuard.xcodeproj -scheme EyeGuard -configuration Release -showBuildSettings 2>/dev/null | grep -m1 "BUILT_PRODUCTS_DIR" | awk '{print $3}')
EYEGUARD_APP="$(find "$APP_PATH" -name "EyeGuard.app" -type d 2>/dev/null | head -1)"
if [[ -z "$EYEGUARD_APP" ]]; then
    echo "Error: EyeGuard.app not found in $APP_PATH"
    exit 1
fi
echo "    Found: $EYEGUARD_APP"
cp -R "$EYEGUARD_APP" "$RELEASE_DIR/EyeGuard.app"
echo "    Copied to $RELEASE_DIR/EyeGuard.app"

# 2. Copy CLI
if [[ -f "$CLI_SRC" ]]; then
    echo "==> Copying eyeguard CLI..."
    cp "$CLI_SRC" "$RELEASE_DIR/eyeguard"
    chmod +x "$RELEASE_DIR/eyeguard"
    echo "    Copied to $RELEASE_DIR/eyeguard"
else
    echo "Warning: $CLI_SRC not found, skipping CLI"
fi

# 3. Copy SKILL
if [[ -f "$SKILL_SRC" ]]; then
    echo "==> Copying eyeguard-cli SKILL..."
    cp "$SKILL_SRC" "$RELEASE_DIR/eyeguard-cli.SKILL.md"
    echo "    Copied to $RELEASE_DIR/eyeguard-cli.SKILL.md"
else
    echo "Warning: $SKILL_SRC not found, skipping SKILL"
fi

# 4. Compress App
echo "==> Compressing EyeGuard.app..."
(cd "$RELEASE_DIR" && zip -r "EyeGuard.app.zip" "EyeGuard.app" -x "*.DS_Store" && rm -rf "EyeGuard.app")
APP_ZIP="$RELEASE_DIR/EyeGuard.app.zip"
APP_ZIP_SIZE=$(du -h "$APP_ZIP" | cut -f1)
echo "    Created EyeGuard.app.zip (${APP_ZIP_SIZE})"

# 5. Generate README
echo "==> Generating README..."
cat > "$RELEASE_DIR/README.md" << "README_EOF"
# EyeGuard 护眼卫士 — Release

## 目录结构

```
EyeGuard.app.zip/  macOS App（解压后安装）
eyeguard           命令行工具
eyeguard-cli.SKILL.md  CLI 使用说明
README.md          本文件
```

## 安装

### App
1. 解压 `EyeGuard.app.zip`
2. 拷贝 `EyeGuard.app` 到 `/Applications/`

### CLI（可选）
```bash
cp eyeguard ~/.hermes/bin/eyeguard
chmod +x ~/.hermes/bin/eyeguard
```

## 快捷键

| 按键 | 行为 |
|------|------|
| ⌘⇧E | 继续工作 |
| ⌘⇧P | 暂停计时 |

## CLI 命令

```bash
eyeguard status      # 查看状态
eyeguard start      # 开始工作
eyeguard pause      # 暂停
eyeguard resume     # 继续
eyeguard reset      # 重置
eyeguard rest-now   # 立即休息
eyeguard skip       # 跳过休息
eyeguard stats      # 今日统计
eyeguard settings   # 查看配置
eyeguard set-style <name>  # 切换样式
eyeguard launch     # 启动 App
eyeguard quit       # 退出 App
eyeguard dim        # 暗屏
eyeguard bright     # 亮屏
```

## 状态栏样式

classic | minimal | emoji | compact | bracket | star

---
Built: $BUILD_DATE
README_EOF

echo ""
echo "==> Done. Release/ contents:"
ls -lh "$RELEASE_DIR"
