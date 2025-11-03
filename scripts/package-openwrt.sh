#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "usage: $0 <archive> <openwrt-arch> <version> <output-dir>" >&2
  exit 1
fi

ARCHIVE="$1"
ARCH="$2"
VERSION="$3"
OUT_DIR="$4"

if [[ ! -f "$ARCHIVE" ]]; then
  echo "archive not found: $ARCHIVE" >&2
  exit 1
fi

TMP_ROOT="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

tar -C "$TMP_ROOT" -xf "$ARCHIVE"

PKG_DIR="$TMP_ROOT/pkg"
INSTALL_ROOT="$PKG_DIR/usr/bin"
CONTROL_DIR="$PKG_DIR/CONTROL"
mkdir -p "$INSTALL_ROOT" "$CONTROL_DIR"

BIN_NAME="codex-litellm"
if [[ -f "$TMP_ROOT/${BIN_NAME}.exe" ]]; then
  echo "Windows archive is not supported for OpenWrt packaging" >&2
  exit 1
fi

install -m 0755 "$TMP_ROOT/$BIN_NAME" "$INSTALL_ROOT/$BIN_NAME"

cat >"$CONTROL_DIR/control" <<EOF
Package: codex-litellm
Version: $VERSION
Architecture: $ARCH
Maintainer: Avikalpa <npm@avikalpa.dev>
Section: utils
Priority: optional
Depends:
Source: https://github.com/avikalpa/codex-litellm
Description: Patched OpenAI Codex CLI with LiteLLM support
EOF

mkdir -p "$OUT_DIR"
opkg-build -o root -g root "$PKG_DIR" "$OUT_DIR" >/dev/null

echo "OpenWrt package written to $OUT_DIR"
