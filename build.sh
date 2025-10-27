#!/usr/bin/env bash
set -euo pipefail

export PATH="${HOME}/.cargo/bin:${PATH}"

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TARGET="${TARGET:-x86_64-unknown-linux-gnu}"
SUFFIX="${SUFFIX:-}"
USE_CROSS="${USE_CROSS:-0}"
PATCH_FILE="${ROOT_DIR}/stable-tag.patch"
CODEX_DIR="${ROOT_DIR}/codex"
DIST_ROOT="${ROOT_DIR}/dist"
BINARY_NAME="codex-litellm"

if [[ -z "$SUFFIX" ]]; then
  case "$TARGET" in
    x86_64-unknown-linux-gnu) SUFFIX="linux-x64" ;;
    aarch64-unknown-linux-gnu) SUFFIX="linux-arm64" ;;
    aarch64-linux-android) SUFFIX="android-arm64" ;;
    x86_64-apple-darwin) SUFFIX="macos-x64" ;;
    aarch64-apple-darwin) SUFFIX="macos-arm64" ;;
    x86_64-pc-windows-msvc) SUFFIX="windows-x64" ;;
    aarch64-pc-windows-msvc) SUFFIX="windows-arm64" ;;
    x86_64-unknown-freebsd) SUFFIX="freebsd-x64" ;;
    x86_64-unknown-illumos) SUFFIX="illumos-x64" ;;
    *)
      echo "Unable to infer suffix for target $TARGET" >&2
      exit 1
      ;;
  esac
fi

if [[ "$USE_CROSS" == "1" || "$USE_CROSS" == "true" ]]; then
  export PKG_CONFIG_ALLOW_CROSS=1
  inherit_vars="PKG_CONFIG_ALLOW_CROSS"
  if [[ "$TARGET" == "x86_64-unknown-illumos" ]]; then
    inherit_vars="${inherit_vars},CFLAGS_x86_64_unknown_illumos,CFLAGS"
  fi
  if [[ -n "${CROSS_CONTAINER_INHERITS:-}" ]]; then
    export CROSS_CONTAINER_INHERITS="${CROSS_CONTAINER_INHERITS},${inherit_vars}"
  else
    export CROSS_CONTAINER_INHERITS="${inherit_vars}"
  fi
fi

if [[ "$TARGET" == "x86_64-unknown-illumos" ]]; then
  export CFLAGS_x86_64_unknown_illumos="${CFLAGS_x86_64_unknown_illumos:-} -D__illumos__"
  export CFLAGS="${CFLAGS:-} -D__illumos__"
fi

mkdir -p "$DIST_ROOT"

if [[ ! -d "$CODEX_DIR" ]]; then
  echo "Cloning openai/codex..."
  git clone https://github.com/openai/codex.git "$CODEX_DIR"
fi

cd "$CODEX_DIR"

echo "Fetching tags and checking out the latest stable release..."
git fetch --tags --quiet
LATEST_STABLE_TAG=$(git tag | grep "^rust-v" | grep -v "alpha\|beta" | sed 's/^rust-v//' | sed 's/^\.//' | sort -V | tail -n 1)

if [[ -z "$LATEST_STABLE_TAG" ]]; then
  echo "Error: Could not determine latest stable tag" >&2
  exit 1
fi

echo "Checking out rust-v${LATEST_STABLE_TAG}"
git checkout "rust-v${LATEST_STABLE_TAG}" --quiet

echo "Resetting tree and applying patch..."
git reset --hard HEAD --quiet
patch -p1 < "$PATCH_FILE"

CARGO_CMD="cargo"
if [[ "$USE_CROSS" == "1" || "$USE_CROSS" == "true" ]]; then
  CARGO_CMD="cross"
fi

CODEX_RS_DIR="${CODEX_DIR}/codex-rs"
if [[ ! -d "$CODEX_RS_DIR" ]]; then
  echo "codex-rs workspace not found" >&2
  exit 1
fi

if [[ -f "${ROOT_DIR}/Cross.toml" ]]; then
  cp "${ROOT_DIR}/Cross.toml" "${CODEX_RS_DIR}/Cross.toml"
  cleanup_cross_toml() { rm -f "${CODEX_RS_DIR}/Cross.toml"; }
  trap cleanup_cross_toml EXIT
fi

cd "$CODEX_RS_DIR"

if [[ "$CARGO_CMD" == "cargo" ]]; then
  rustup target add "$TARGET" >/dev/null 2>&1 || true
fi

echo "Building target $TARGET using $CARGO_CMD"
$CARGO_CMD build --release --target "$TARGET"

ARTIFACT_DIR="$DIST_ROOT/$SUFFIX"
mkdir -p "$ARTIFACT_DIR"

if [[ "$TARGET" == *"windows"* ]]; then
  SRC_BIN="target/$TARGET/release/codex.exe"
  DEST_BIN="$ARTIFACT_DIR/${BINARY_NAME}.exe"
else
  SRC_BIN="target/$TARGET/release/codex"
  DEST_BIN="$ARTIFACT_DIR/${BINARY_NAME}"
fi

if [[ ! -f "$SRC_BIN" ]]; then
  echo "Built binary not found at $SRC_BIN" >&2
  exit 1
fi

cp "$SRC_BIN" "$DEST_BIN"
chmod +x "$DEST_BIN"

cd "$DIST_ROOT"
ARCHIVE_NAME="codex-litellm-${SUFFIX}.tar.gz"

tar -C "$SUFFIX" -czf "$ARCHIVE_NAME" .
sha256sum "$ARCHIVE_NAME" > "${ARCHIVE_NAME}.sha256"

echo "Artifact ready: $DIST_ROOT/$ARCHIVE_NAME"
