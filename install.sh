#!/bin/bash
# EyeGuard install script
# Usage: ./install.sh [version]  (default: latest)

set -e

# ── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()  { echo -e "${CYAN}→${NC} $1"; }
log_ok()    { echo -e "${GREEN}✓${NC} $1"; }
log_warn()  { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

# ── Version ────────────────────────────────────────────────────────────────
VERSION=${1:-}
if [ -z "$VERSION" ]; then
  log_info "Fetching latest version..."
  VERSION=$(curl -s https://api.github.com/repos/lyloou/eyeguard/releases/latest \
    | grep -o '"tag_name": "[^"]*"' | grep -o 'v[0-9.]*')
fi

REPO="lyloou/eyeguard"
BASE_URL="https://github.com/$REPO/releases/download/$VERSION"
ZIP_URL="$BASE_URL/${VERSION}.zip"

log_info "Installing EyeGuard $VERSION ..."

# ── Download & extract ─────────────────────────────────────────────────────
TMP=$(mktemp -d)
cd "$TMP"

log_info "Downloading $ZIP_URL ..."
if ! curl -L "$ZIP_URL" -o eyeguard.zip; then
  log_error "Download failed. Check version: $VERSION"
  exit 1
fi

log_info "Extracting ..."
unzip -o eyeguard.zip

# ── Install App ────────────────────────────────────────────────────────────
if [ -f "Release/EyeGuard.app.zip" ]; then
  log_info "Installing EyeGuard.app to /Applications/ ..."
  unzip -o "Release/EyeGuard.app.zip" -d /Applications/
  log_ok "EyeGuard.app installed"
fi

# ── Install CLI ─────────────────────────────────────────────────────────────
if [ -f "Release/eyeguard" ]; then
  log_info "Installing eyeguard CLI ..."
  mkdir -p ~/.eyeguard/bin
  cp Release/eyeguard ~/.eyeguard/bin/
  chmod +x ~/.eyeguard/bin/eyeguard
  log_ok "CLI installed to ~/.eyeguard/bin/eyeguard"
fi

# ── Configure PATH ─────────────────────────────────────────────────────────
SHELL_RC="$HOME/.zshrc"
if ! grep -q 'eyeguard/bin' "$SHELL_RC" 2>/dev/null; then
  echo '' >> "$SHELL_RC"
  echo 'export PATH="$HOME/.eyeguard/bin:$PATH"' >> "$SHELL_RC"
  log_info "Added ~/.eyeguard/bin to PATH in ~/.zshrc"
else
  log_info "PATH already configured"
fi

# ── Done ───────────────────────────────────────────────────────────────────
echo ""
log_ok "EyeGuard $VERSION installed!"
echo ""
log_info "Next steps:"
echo "  source ~/.zshrc"
echo "  eyeguard --help"
