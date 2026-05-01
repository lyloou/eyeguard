#!/bin/bash
# EyeGuard Release Script
# Usage:
#   ./scripts/release.sh <version>   (e.g. ./scripts/release.sh 0.1.6 或 v0.1.6)
#   ./scripts/release.sh             # 从 GitHub latest release 的 tag_name（须为 vx.y.z）取上一版后 patch +1

set -e

REPO="lyloou/eyeguard"
GITHUB_LATEST_JSON_URL="https://api.github.com/repos/${REPO}/releases/latest"

# fetch_github_latest_tag_name
#
# 请求 GitHub Releases API latest，stdout 输出 tag_name 原始字符串。
#
# 在未安装 jq/python3、或 curl 失败时以非零退出。
fetch_github_latest_tag_name() {
  local json
  json="$(curl -fsSL "$GITHUB_LATEST_JSON_URL")" || return 1
  if command -v jq >/dev/null 2>&1; then
    jq -r '.tag_name // empty' <<< "$json"
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["tag_name"])' <<< "$json"
  else
    tr -d '\n' <<< "$json" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'
  fi
}

# semver_from_github_tag_strict
#
# 要求 tag_name 严格为前缀 v + x.y.z；stdout 输出无 v 的 semver。
#
# Args:
#   $1 — 例如 v0.1.8
# 返回非零 — 不符合 vx.y.z。
semver_from_github_tag_strict() {
  local tag="$1"
  if [[ ! "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "semver_from_github_tag_strict: 非法 tag_name: '$tag'（须严格为 vx.y.z，例如 v0.1.8）" >&2
    return 1
  fi
  printf '%s' "${tag#v}"
}

# bump_patch_semver
#
# 将 x.y.z 的第三位 +1。
#
# Args:
#   $1 — semver，无 v 前缀
bump_patch_semver() {
  local raw="$1"
  if [[ ! "$raw" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    echo "bump_patch_semver: invalid semver '$raw' (want x.y.z)" >&2
    return 1
  fi
  printf '%s.%s.%s' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "$((BASH_REMATCH[3] + 1))"
}

VERSION=${1:-}
if [ -z "$VERSION" ]; then
  prev_tag="$(fetch_github_latest_tag_name)" || {
    echo "无法获取 $GITHUB_LATEST_JSON_URL（无 Release、网络错误或未安装 jq/python3 且响应无法解析）。请显式指定: $0 <x.y.z>" >&2
    exit 1
  }
  if [ -z "$prev_tag" ]; then
    echo "响应中无 tag_name。请显式指定: $0 <x.y.z>" >&2
    exit 1
  fi
  prev_semver="$(semver_from_github_tag_strict "$prev_tag")" || exit 1
  VERSION="$(bump_patch_semver "$prev_semver")" || exit 1
  echo "[info] 基于 GitHub latest：上一次 ${prev_tag} → 本次 v${VERSION}"
else
  VERSION="${VERSION#v}"
fi

PROJECT_DIR=$(cd "$(dirname "$0")/.." && pwd)
RELEASE_DIR="$PROJECT_DIR/Release"
ARCHIVE_DIR="$PROJECT_DIR/Archive"
ZIP_NAME="v${VERSION}.zip"
DERIVED_RELEASE="$PROJECT_DIR/.build/ReleaseDerivedData"
BUILD_PRODUCTS="$DERIVED_RELEASE/Build/Products/Release"

cd "$PROJECT_DIR"

echo "=== EyeGuard Release v${VERSION} ==="
echo ""

# 1. Build App（独立 DerivedData，每次发布前清空，避免旧缓存）
echo "[1/5] Building EyeGuard.app ..."
echo "清空本地 Release DerivedData ($DERIVED_RELEASE) ..."
rm -rf "$DERIVED_RELEASE"
xcodegen generate -q
BUILD_LOG=$(mktemp)
xcodebuild -project EyeGuard.xcodeproj \
  -scheme EyeGuard \
  -configuration Release \
  -derivedDataPath "$DERIVED_RELEASE" \
  clean build \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO 2>&1 | tee "$BUILD_LOG"
if grep -qE " error:" "$BUILD_LOG"; then
  echo "xcodebuild 失败，详见上方日志" >&2
  rm -f "$BUILD_LOG"
  exit 1
fi
rm -f "$BUILD_LOG"

# 2. Prepare Release dir
echo ""
echo "[2/5] Preparing Release directory ..."
mkdir -p "$RELEASE_DIR"
rm -rf "$RELEASE_DIR/EyeGuard.app" "$RELEASE_DIR/EyeGuard.app.zip" "$RELEASE_DIR/eyeguard"
cp -r "$BUILD_PRODUCTS/EyeGuard.app" "$RELEASE_DIR/"
cp -f "$PROJECT_DIR/eyeguard" "$RELEASE_DIR/eyeguard"
chmod +x "$RELEASE_DIR/eyeguard"

# 3. Package App zip
echo ""
echo "[3/5] Packaging EyeGuard.app.zip ..."
cd "$RELEASE_DIR"
zip -r EyeGuard.app.zip EyeGuard.app
cd "$PROJECT_DIR"

# 4. Create zip bundle
echo ""
echo "[4/5] Creating $ZIP_NAME ..."
mkdir -p "$ARCHIVE_DIR"
rm -f "$ARCHIVE_DIR/$ZIP_NAME"
zip -r "$ARCHIVE_DIR/$ZIP_NAME" Release/ install.sh eyeguard skills/

# 5. Upload to GitHub
echo ""
echo "[5/5] Uploading to GitHub Release ..."
gh release create "v${VERSION}" \
  --title "EyeGuard v${VERSION}" \
  --notes "Release v${VERSION}" \
  "$ARCHIVE_DIR/$ZIP_NAME"

echo ""
echo "=== Done ==="
echo "Release: https://github.com/$REPO/releases/tag/v${VERSION}"
echo "Install:"
echo "  curl -L https://github.com/$REPO/releases/download/v${VERSION}/$ZIP_NAME | funzip | bash"
