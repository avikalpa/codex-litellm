#!/usr/bin/env bash

set -euo pipefail

fixture="${1:-mini-web}"
profile="${2:-/home/pi/.codex-litellm-debug}"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failures=()
mapfile -t models < <(
  "$repo_root/scripts/discover-agentic-models.sh" \
    --profile "$profile" \
    deepseek minimax kimi
)

for model in "${models[@]}"; do
  echo
  echo "=== Running $model on $fixture ==="
  if "$repo_root/scripts/run-agentic-model-smoke.sh" \
    --fixture "$fixture" \
    --model "$model" \
    --profile "$profile"; then
    echo "PASS $model"
  else
    echo "FAIL $model" >&2
    failures+=("$model")
  fi
done

if [[ "${#failures[@]}" -gt 0 ]]; then
  echo
  echo "Failed models:" >&2
  printf ' - %s\n' "${failures[@]}" >&2
  exit 1
fi
