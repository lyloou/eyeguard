#!/bin/bash
# restart.sh — 编译并重启 EyeGuard App
#
# 使用项目内 .build/DerivedData：每次运行前整目录删除，避免使用 Xcode 全局缓存的旧产物。

set -e

PROJECT_DIR=$(cd "$(dirname "$0")/.." && pwd)
DERIVED_DATA="$PROJECT_DIR/.build/DerivedData"
APP_PATH="$DERIVED_DATA/Build/Products/Debug/EyeGuard.app"

cd "$PROJECT_DIR"

echo "清空本地 DerivedData ($DERIVED_DATA) ..."
rm -rf "$DERIVED_DATA"

echo "同步 Xcode 工程 ..."
xcodegen generate -q

echo "正在编译..."
BUILD_LOG=$(mktemp)
xcodebuild -project EyeGuard.xcodeproj \
  -scheme EyeGuard \
  -configuration Debug \
  -derivedDataPath "$DERIVED_DATA" \
  build \
  -destination 'platform=macOS,arch=arm64' \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGNING_REQUIRED=NO \
  -quiet 2>&1 | tee "$BUILD_LOG"
if grep -qE " error:" "$BUILD_LOG"; then
  echo "编译失败" >&2
  rm -f "$BUILD_LOG"
  exit 1
fi
rm -f "$BUILD_LOG"
echo "编译成功"

if pgrep -x "EyeGuard" > /dev/null 2>&1; then
  echo "EyeGuard 正在运行，关掉..."
  osascript -e 'quit app "EyeGuard"' 2>/dev/null || killall EyeGuard 2>/dev/null
  sleep 1
fi

rm -f /tmp/eyeguard.lock /tmp/eyeguard.sock

if [[ -d "$APP_PATH" ]]; then
  echo "启动 EyeGuard ($APP_PATH)..."
  open -a "$APP_PATH"
else
  echo "Error: 找不到 EyeGuard.app: $APP_PATH" >&2
  exit 1
fi

echo "EyeGuard 已启动"
