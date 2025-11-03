#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "usage: $0 <archive> <termux-arch> <version> <output-dir>" >&2
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
DEBIAN_DIR="$PKG_DIR/DEBIAN"
BIN_DIR="$PKG_DIR/data/data/com.termux/files/usr/bin"
DOC_DIR="$PKG_DIR/data/data/com.termux/files/usr/share/doc/codex-litellm"
mkdir -p "$DEBIAN_DIR" "$BIN_DIR" "$DOC_DIR"

BIN_NAME="codex-litellm"
if [[ -f "$TMP_ROOT/${BIN_NAME}.exe" ]]; then
  echo "Windows archive is not supported for Termux packaging" >&2
  exit 1
fi

install -m 0755 "$TMP_ROOT/$BIN_NAME" "$BIN_DIR/$BIN_NAME"
install -m 0644 "$TMP_ROOT/LICENSE" "$DOC_DIR/LICENSE"
install -m 0644 "$TMP_ROOT/NOTICE" "$DOC_DIR/NOTICE"

cat >"$DEBIAN_DIR/control" <<EOF
Package: codex-litellm
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Maintainer: Avikalpa <npm@avikalpa.dev>
Depends: termux-tools
Description: Patched OpenAI Codex CLI with LiteLLM support for Termux environments
EOF

mkdir -p "$OUT_DIR"
dpkg-deb --build "$PKG_DIR" "$OUT_DIR/codex-litellm_${VERSION}_${ARCH}.deb" >/dev/null

echo "Termux package written to $OUT_DIR"
