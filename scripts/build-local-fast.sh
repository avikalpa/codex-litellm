#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workspace_root="$repo_root/codex/codex-rs"
target_bin="codex-litellm"

if command -v sccache >/dev/null 2>&1; then
  export RUSTC_WRAPPER="${RUSTC_WRAPPER:-sccache}"
  export SCCACHE_DIR="${SCCACHE_DIR:-$HOME/.cache/sccache-codex-litellm}"
fi

export CARGO_INCREMENTAL="${CARGO_INCREMENTAL:-1}"
export RUSTFLAGS="${RUSTFLAGS:--Cdebuginfo=0}"

cd "$workspace_root"
cargo build --locked -p codex-cli --bin "$target_bin" "$@"

printf '\nBuilt: %s/target/debug/%s\n' "$workspace_root" "$target_bin"
