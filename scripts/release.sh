#!/bin/bash
# EyeGuard Release Script
# Usage: ./scripts/release.sh [version]  (e.g., ./scripts/release.sh 0.1.4)

set -e

VERSION=${1:-}
if [ -z "$VERSION" ]; then
  echo "Usage: $0 <version>"
  echo "Example: $0 0.1.4"
  exit 1
fi

REPO="lyloou/eyeguard"
ZIP_NAME="v${VERSION}.zip"
PROJECT_DIR=$(cd "$(dirname "$0")/.." && pwd)
RELEASE_DIR="$PROJECT_DIR/Release"
BUILD_PRODUCTS="$HOME/Library/Developer/Xcode/DerivedData/EyeGuard-cgpwcqmjssschbghvdincznbhyro/Build/Products/Release"

cd "$PROJECT_DIR"

echo "=== EyeGuard Release v${VERSION} ==="
echo "Timestamp: $TIMESTAMP"
echo ""

# 1. Build App
echo "[1/5] Building EyeGuard.app ..."
xcodebuild -project EyeGuard.xcodeproj \
  -scheme EyeGuard \
  -configuration Release \
  build \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO 2>&1 | tail -3

# 2. Prepare Release dir
echo ""
echo "[2/5] Preparing Release directory ..."
mkdir -p "$RELEASE_DIR"
rm -rf "$RELEASE_DIR/EyeGuard.app" "$RELEASE_DIR/EyeGuard.app.zip"
cp -r "$BUILD_PRODUCTS/EyeGuard.app" "$RELEASE_DIR/"

# 3. Package App zip
echo ""
echo "[3/5] Packaging EyeGuard.app.zip ..."
cd "$RELEASE_DIR"
zip -r EyeGuard.app.zip EyeGuard.app
cd "$PROJECT_DIR"

# 5. Create zip bundle
echo ""
echo "[4/4] Creating $ZIP_NAME ..."
rm -f "$PROJECT_DIR/$ZIP_NAME"
zip -r "$PROJECT_DIR/$ZIP_NAME" Release/ install.sh eyeguard-cli.SKILL.md

# 6. Create GitHub Release & upload
echo ""
echo "=== Creating GitHub Release ==="
gh release create "v${VERSION}" \
  --title "EyeGuard v${VERSION}" \
  --notes "Release v${VERSION}" \
  "$ZIP_NAME"

echo ""
echo "=== Done ==="
echo "Release: https://github.com/$REPO/releases/tag/v${VERSION}"
echo "Install: curl -L https://github.com/$REPO/releases/download/v${VERSION}/$ZIP_NAME | funzip | bash"
