#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR/codex/codex-rs"

cargo test -p codex-core \
  --test all \
  responses_mode_stream_codex_litellm_uses_default_home \
  -- --nocapture
