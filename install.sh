#!/bin/bash
# EyeGuard install script
# Usage: ./install.sh [version]  (default: latest)

set -e

VERSION=${1:-latest}
REPO="lyloou/eyeguard"
BASE_URL="https://github.com/$REPO/releases/download/$VERSION"

echo "Installing EyeGuard $VERSION ..."

TMP=$(mktemp -d)
cd "$TMP"

curl -L "$BASE_URL/v${VERSION}.zip" -o eyeguard.zip
unzip -o eyeguard.zip

if [ -f "Release/EyeGuard.app.zip" ]; then
  unzip -o "Release/EyeGuard.app.zip" -d /Applications/
fi

if [ -f "Release/eyeguard" ]; then
  mkdir -p ~/.eyeguard/bin
  cp Release/eyeguard ~/.eyeguard/bin/
  chmod +x ~/.eyeguard/bin/eyeguard
fi

SHELL_RC="$HOME/.zshrc"
if ! grep -q 'eyeguard/bin' "$SHELL_RC" 2>/dev/null; then
  echo 'export PATH="$HOME/.eyeguard/bin:$PATH"' >> "$SHELL_RC"
fi

echo ""
echo "Done! Run: source ~/.zshrc && eyeguard --help"
