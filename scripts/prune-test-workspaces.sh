#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
keep_path="${1:-}"
keep_real=""

if [[ -n "$keep_path" ]]; then
  keep_real="$(realpath -m "$keep_path")"
fi

shopt -s nullglob
for dir in "$repo_root"/test-workspace*; do
  [[ -d "$dir" ]] || continue
  dir_real="$(realpath -m "$dir")"
  if [[ -n "$keep_real" && "$dir_real" == "$keep_real" ]]; then
    continue
  fi
  rm -rf "$dir"
done
