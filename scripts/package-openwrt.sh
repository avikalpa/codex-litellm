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

DATA_DIR="$TMP_ROOT/data"
CONTROL_DIR="$TMP_ROOT/control"
INSTALL_ROOT="$DATA_DIR/usr/bin"
LICENSE_DIR="$DATA_DIR/usr/share/licenses/codex-litellm"
mkdir -p "$INSTALL_ROOT" "$CONTROL_DIR"

BIN_NAME="codex-litellm"
if [[ -f "$TMP_ROOT/${BIN_NAME}.exe" ]]; then
  echo "Windows archive is not supported for OpenWrt packaging" >&2
  exit 1
fi

install -m 0755 "$TMP_ROOT/$BIN_NAME" "$INSTALL_ROOT/$BIN_NAME"
mkdir -p "$LICENSE_DIR"
install -m 0644 "$TMP_ROOT/LICENSE" "$LICENSE_DIR/LICENSE"
install -m 0644 "$TMP_ROOT/NOTICE" "$LICENSE_DIR/NOTICE"

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
DATA_TAR="$TMP_ROOT/data.tar.gz"
CONTROL_TAR="$TMP_ROOT/control.tar.gz"
(
  cd "$DATA_DIR"
  tar --owner=0 --group=0 -czf "$DATA_TAR" .
)
(
  cd "$CONTROL_DIR"
  tar --owner=0 --group=0 -czf "$CONTROL_TAR" .
)
echo "2.0" > "$TMP_ROOT/debian-binary"
OUTPUT_IPK="$OUT_DIR/codex-litellm_${VERSION}_${ARCH}.ipk"
ar rcs "$OUTPUT_IPK" "$TMP_ROOT/debian-binary" "$CONTROL_TAR" "$DATA_TAR"

echo "OpenWrt package written to $OUT_DIR"
