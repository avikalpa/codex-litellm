#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TARGET="${TARGET:-x86_64-unknown-linux-gnu}"
USE_CROSS="${USE_CROSS:-0}"
PATCH_FILE="${ROOT_DIR}/stable-tag.patch"
CODEX_DIR="${ROOT_DIR}/codex"
DIST_ROOT="${ROOT_DIR}/dist"
BINARY_NAME="codex-litellm"

case "$TARGET" in
  x86_64-unknown-linux-gnu)
    PACKAGE_SUFFIX="linux-x64"
    ;;
  aarch64-linux-android)
    PACKAGE_SUFFIX="android-arm64"
    ;;
  *)
    echo "Unsupported target: $TARGET" >&2
    exit 1
    ;;
esac

mkdir -p "$DIST_ROOT"

if [ ! -d "$CODEX_DIR" ]; then
  echo "Cloning openai/codex..."
  git clone https://github.com/openai/codex.git "$CODEX_DIR"
fi

cd "$CODEX_DIR"

echo "Fetching tags and checking out the latest stable release..."
git fetch --tags
LATEST_STABLE_TAG=$(git tag | grep "^rust-v" | grep -v "alpha\|beta" | sed 's/^rust-v//' | sed 's/^\.//' | sort -V | tail -n 1)

if [ -z "$LATEST_STABLE_TAG" ]; then
  echo "Error: Could not determine latest stable tag" >&2
  exit 1
fi

echo "Checking out rust-v${LATEST_STABLE_TAG}"
git checkout "rust-v${LATEST_STABLE_TAG}"

if [ ! -f "$PATCH_FILE" ]; then
  echo "Patch file not found: $PATCH_FILE" >&2
  exit 1
fi

echo "Resetting tree and applying patch..."
git reset --hard HEAD
patch -p1 < "$PATCH_FILE"

echo "Building target $TARGET"
if [ "$USE_CROSS" != "0" ]; then
  cross build --release --target "$TARGET"
else
  rustup target add "$TARGET" >/dev/null 2>&1 || true
  cargo build --release --target "$TARGET"
fi

ARTIFACT_DIR="$DIST_ROOT/$TARGET"
mkdir -p "$ARTIFACT_DIR"

SRC_BIN="target/$TARGET/release/codex"
if [ ! -f "$SRC_BIN" ]; then
  echo "Built binary not found at $SRC_BIN" >&2
  exit 1
fi

cp "$SRC_BIN" "$ARTIFACT_DIR/$BINARY_NAME"
chmod +x "$ARTIFACT_DIR/$BINARY_NAME"

ARCHIVE_NAME="codex-litellm-${PACKAGE_SUFFIX}.tar.gz"
ARCHIVE_PATH="$DIST_ROOT/$ARCHIVE_NAME"

tar -C "$ARTIFACT_DIR" -czf "$ARCHIVE_PATH" "$BINARY_NAME"

( cd "$DIST_ROOT" && sha256sum "$ARCHIVE_NAME" > "${ARCHIVE_NAME}.sha256" )

echo "Artifact ready: $ARCHIVE_PATH"
