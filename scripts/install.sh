#!/bin/bash
# install.sh — 一键安装 EyeGuard 护眼卫士
set -e

# ── 配置 ──────────────────────────────────────────────────────
REPO="lyloou/eyeguard"
INSTALL_DIR="$HOME/.eyeguard/bin"
APP_DEST="/Applications/EyeGuard.app"
GH="gh"

# ── 颜色 ─────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ── 解析版本 ─────────────────────────────────────────────────
VERSION="$1"
if [[ -z "$VERSION" ]]; then
    info "未指定版本，使用 latest..."
    DOWNLOAD_URL="https://github.com/$REPO/releases/latest/download"
else
    DOWNLOAD_URL="https://github.com/$REPO/releases/download/v${VERSION#v}"
fi

info "下载来源: $DOWNLOAD_URL"

# ── 创建目录 ─────────────────────────────────────────────────
mkdir -p "$INSTALL_DIR"

# ── 下载并安装 App ───────────────────────────────────────────
info "下载 EyeGuard.app..."
TMP_ZIP="/tmp/eyeguard_app.zip"
curl -fsSL "$DOWNLOAD_URL/EyeGuard.app.zip" -o "$TMP_ZIP"

# 解压到 /Applications（覆盖安装）
info "安装 EyeGuard.app 到 $APP_DEST..."
rm -rf "$APP_DEST"
unzip -q "$TMP_ZIP" -d "/Applications/"
rm -f "$TMP_ZIP"

# ── 下载并安装 CLI ───────────────────────────────────────────
info "安装 eyeguard CLI..."
CLI_URL="$DOWNLOAD_URL/eyeguard"
curl -fsSL "$CLI_URL" -o "$INSTALL_DIR/eyeguard"
chmod +x "$INSTALL_DIR/eyeguard"

# ── 配置 PATH ────────────────────────────────────────────────
SHELL_RC="$HOME/.zshrc"
PATH_LINE='export PATH="$HOME/.eyeguard/bin:$PATH"'

if [[ -f "$SHELL_RC" ]] && ! grep -q "\.eyeguard/bin" "$SHELL_RC"; then
    echo "" >> "$SHELL_RC"
    echo "# EyeGuard CLI" >> "$SHELL_RC"
    echo "$PATH_LINE" >> "$SHELL_RC"
    info "已追加 PATH 到 $SHELL_RC，请运行: source $SHELL_RC"
elif [[ ! -f "$SHELL_RC" ]]; then
    warn "未找到 $SHELL_RC，请手动添加: $PATH_LINE"
fi

# ── 完成 ─────────────────────────────────────────────────────
info "安装完成！"
echo ""
echo "  App: $APP_DEST"
echo "  CLI: $INSTALL_DIR/eyeguard"
echo ""
echo "  运行以下命令激活 CLI:"
echo "    source ~/.zshrc"
echo "    eyeguard status"
echo ""
