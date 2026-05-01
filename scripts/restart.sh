#!/bin/bash
# restart.sh — 编译并重启 EyeGuard App

set -e

DERIVED_DATA=$(find "$HOME/Library/Developer/Xcode/DerivedData" -maxdepth 5 \
    -name "EyeGuard.app" -path "*/Debug/EyeGuard.app" 2>/dev/null | head -1)
PROJECT_DIR=$(cd "$(dirname "$0")/.." && pwd)

# 1. 同步 xcodeproj（确保新增文件被纳入编译）
xcodegen generate -q

# 2. 编译
echo "正在编译..."
BUILD_LOG=$(mktemp)
xcodebuild -scheme EyeGuard -configuration Debug build \
    -destination 'platform=macOS,arch=arm64' \
    CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO \
    -quiet 2>&1 | tee "$BUILD_LOG"
if grep -qE " error:" "$BUILD_LOG"; then
    echo "编译失败" >&2
    rm -f "$BUILD_LOG"
    exit 1
fi
rm -f "$BUILD_LOG"
echo "编译成功"

# 2. 杀掉运行中的实例
if pgrep -x "EyeGuard" > /dev/null 2>&1; then
    echo "EyeGuard 正在运行，关掉..."
    osascript -e 'quit app "EyeGuard"' 2>/dev/null || killall EyeGuard 2>/dev/null
    sleep 1
fi

# 3. 清理残留文件
rm -f /tmp/eyeguard.lock /tmp/eyeguard.sock

# 4. 启动 DerivedData 中的最新构建
if [[ -d "$DERIVED_DATA" ]]; then
    echo "启动 EyeGuard (DerivedData)..."
    open -a "$DERIVED_DATA"
else
    echo "Error: 找不到 EyeGuard.app" >&2
    exit 1
fi

echo "EyeGuard 已启动"
