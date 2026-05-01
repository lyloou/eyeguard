#!/bin/bash
# EyeGuard install script
# Usage: ./install.sh [version]  (default: latest)
#
# 期望 vX.zip 根布局：./EyeGuard.app.zip、./eyeguard、./install.sh、./skills/
#（与 scripts/release.sh 产物一致）。

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

REPO="lyloou/eyeguard"

# resolve_latest_version
#
# 解析 GitHub releases/latest 的 tag_name。优先 jq，否则回退 grep。
#
# Prints: tag，如 v0.1.13。失败时 stdout 为空。
resolve_latest_version() {
  local url="https://api.github.com/repos/${REPO}/releases/latest"
  if command -v jq >/dev/null 2>&1; then
    curl -fsSL "$url" | jq -r '.tag_name // empty'
  else
    curl -fsSL "$url" | grep -o '"tag_name": "[^"]*"' | grep -o 'v[0-9.]*' | head -1
  fi
}

# ── Version ────────────────────────────────────────────────────────────────
VERSION=${1:-}
if [ -z "$VERSION" ]; then
  log_info "Fetching latest version..."
  VERSION="$(resolve_latest_version)"
  if [ -z "$VERSION" ] || [ "$VERSION" = "null" ]; then
    log_error "无法解析最新版本（请检查网络，或安装 jq 后重试；也可显式指定: $0 0.1.13）"
    exit 1
  fi
elif [[ "$VERSION" != v* ]]; then
  VERSION="v${VERSION}"
fi

BASE_URL="https://github.com/$REPO/releases/download/$VERSION"
ZIP_URL="$BASE_URL/${VERSION}.zip"

log_info "Installing EyeGuard $VERSION ..."

# ── Download & extract ─────────────────────────────────────────────────────
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cd "$TMP"

log_info "Downloading $ZIP_URL ..."
if ! curl -fsSL "$ZIP_URL" -o eyeguard.zip; then
  log_error "Download failed. Check version: $VERSION"
  exit 1
fi

log_info "Extracting ..."
unzip -o eyeguard.zip

# ── Install App ────────────────────────────────────────────────────────────
if [ ! -f "./EyeGuard.app.zip" ]; then
  log_error "解压包缺少 EyeGuard.app.zip（根目录）。请下载由本仓库 scripts/release.sh 构建的 Release。"
  exit 1
fi
log_info "Installing EyeGuard.app to /Applications/ ..."
unzip -o "./EyeGuard.app.zip" -d /Applications/
log_ok "EyeGuard.app installed"

# ── Install CLI ─────────────────────────────────────────────────────────────
if [ ! -f "./eyeguard" ]; then
  log_error "解压包缺少 eyeguard CLI 脚本（根目录）。"
  exit 1
fi
log_info "Installing eyeguard CLI (overwrite) ..."
mkdir -p ~/.eyeguard/bin
cp -f "./eyeguard" ~/.eyeguard/bin/eyeguard
chmod +x ~/.eyeguard/bin/eyeguard
log_ok "CLI installed to ~/.eyeguard/bin/eyeguard"

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
