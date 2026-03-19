#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/run-public-smoke-bench.sh [options]

Options:
  --fixture <name>    Fixture to use (default: mini-web)
  --profile <dir>     Codex profile directory (default: ~/.codex)
  --output <file>     Markdown output file
  --json <file>       JSON output file

This script resolves live model IDs from the configured LiteLLM gateway, runs
the basic smoke bench sequentially, and writes sanitized public results that do
not expose private route segments.
EOF
}

fixture="mini-web"
profile="$HOME/.codex"
output_file="benchmarks/public-smoke-results.md"
json_file="benchmarks/public-smoke-results.json"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fixture)
      fixture="$2"
      shift 2
      ;;
    --profile)
      profile="$2"
      shift 2
      ;;
    --output)
      output_file="$2"
      shift 2
      ;;
    --json)
      json_file="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
done

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$(dirname "$output_file")" "$(dirname "$json_file")"

families=(
  minimax
  glm
  claude-haiku
  deepseek
  grok-fast
)

sanitize_slug() {
  local slug="$1"
  IFS='/' read -r -a parts <<<"$slug"
  if [[ "${#parts[@]}" -ge 2 ]]; then
    printf '%s/%s\n' "${parts[0]}" "${parts[${#parts[@]}-1]}"
  else
    printf '%s\n' "$slug"
  fi
}

note_for_family() {
  local family="$1"
  case "$family" in
    minimax)
      printf '%s\n' "Best current value path for Codex-style editing."
      ;;
    glm)
      printf '%s\n' "Rechecked after gateway fix."
      ;;
    claude-haiku)
      printf '%s\n' "Cheap fast route; verify reliability on your own endpoint."
      ;;
    deepseek)
      printf '%s\n' "Known /responses bridge risk around reasoning follow-up turns."
      ;;
    grok-fast)
      printf '%s\n' "Economics-oriented Grok fast reasoning route."
      ;;
  esac
}

mapfile -t resolved_models < <(
  "$repo_root/scripts/discover-agentic-models.sh" --profile "$profile" "${families[@]}"
)

results_json="[]"
display_profile="~/.codex"
if [[ "$profile" != "$HOME/.codex" ]]; then
  display_profile="custom LiteLLM profile"
fi
for i in "${!families[@]}"; do
  family="${families[$i]}"
  resolved="${resolved_models[$i]}"
  public_slug="$(sanitize_slug "$resolved")"
  workspace="test-workspace-bench-${family}"
  note="$(note_for_family "$family")"

  echo
  echo "=== Running ${family} (${public_slug}) on ${fixture} ==="

  set +e
  "$repo_root/scripts/run-agentic-model-smoke.sh" \
    --fixture "$fixture" \
    --workspace "$workspace" \
    --model "$resolved" \
    --profile "$profile"
  status_code=$?
  set -e

  status="fail"
  if [[ "$status_code" -eq 0 ]]; then
    status="pass"
  fi

  results_json="$(
    jq -c \
      --arg family "$family" \
      --arg model "$public_slug" \
      --arg fixture "$fixture" \
      --arg status "$status" \
      --arg note "$note" \
      '. + [{family:$family, model:$model, fixture:$fixture, status:$status, note:$note}]' \
      <<<"$results_json"
  )"
done

printf '%s\n' "$results_json" > "$json_file"

{
  echo "# Public Smoke Bench"
  echo
  echo "Latest live smoke run against a LiteLLM /responses endpoint using the public fixture bench."
  echo
  echo "- fixture: \`$fixture\`"
  echo "- profile path: \`$display_profile\`"
  echo "- exact gateway-specific route segments are intentionally not published"
  echo
  echo "| Model family | Public slug | Status | Notes |"
  echo "| --- | --- | --- | --- |"
  jq -r '.[] | "| \(.family) | `\(.model)` | \(.status) | \(.note) |"' "$json_file"
  echo
  echo "Regenerate with:"
  echo
  echo '```bash'
  echo "scripts/run-public-smoke-bench.sh --profile ~/.codex"
  echo '```'
} > "$output_file"
