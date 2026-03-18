#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"

expected_base=$(node -p "require('./package.json').codexLitellm.baseVersion")
expected_tag="rust-v${expected_base}"
output=$(BUILD_SH_DRY_RUN=1 ./build.sh)

if [[ "$output" != *"BASE_VERSION=${expected_base}"* ]]; then
  echo "build.sh did not resolve the expected base version" >&2
  echo "$output" >&2
  exit 1
fi

if [[ "$output" != *"PINNED_TAG=${expected_tag}"* ]]; then
  echo "build.sh did not resolve the expected pinned tag" >&2
  echo "$output" >&2
  exit 1
fi

echo "build.sh metadata resolution OK: ${expected_tag}"
