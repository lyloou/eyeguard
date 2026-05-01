#!/bin/bash
# restart.sh — 编译并重启 EyeGuard App

set -e

DERIVED_DATA="~/Library/Developer/Xcode/DerivedData/EyeGuard-cgpwcqmjssschbghvdincznbhyro/Build/Products/Debug/EyeGuard.app"
PROJECT_DIR=$(cd "$(dirname "$0")/.." && pwd)

# 1. 编译（若有代码变更才真正重编，xcodebuild 会处理增量）
echo "正在编译..."
if ! xcodebuild -scheme EyeGuard -configuration Debug build \
    CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO \
    -quiet 2>&1 | grep -E "^error:"; then
    echo "编译成功"
else
    echo "编译失败" >&2
    exit 1
fi

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
