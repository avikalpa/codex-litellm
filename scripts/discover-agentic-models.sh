#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/discover-agentic-models.sh [options] <family>...

Families:
  deepseek
  minimax
  kimi
  claude-haiku
  claude-sonnet
  glm

Options:
  --profile <dir>   Profile directory containing config.toml
  --config <file>   Explicit config.toml path

If no config path is provided, the script uses $CODEX_HOME/config.toml, then
falls back to ~/.codex-litellm-debug/config.toml.
EOF
}

config_path=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      config_path="$2/config.toml"
      shift 2
      ;;
    --config)
      config_path="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      usage >&2
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -eq 0 ]]; then
  usage >&2
  exit 1
fi

if [[ -z "$config_path" && -n "${CODEX_HOME:-}" ]]; then
  config_path="$CODEX_HOME/config.toml"
fi

if [[ -z "$config_path" ]]; then
  config_path="$HOME/.codex-litellm-debug/config.toml"
fi

if [[ ! -f "$config_path" ]]; then
  echo "config.toml not found: $config_path" >&2
  exit 1
fi

base_url="$(rg '^base_url = "' "$config_path" | sed -E 's/.*"([^"]+)".*/\1/' | head -n1)"
bearer_token="$(rg '^experimental_bearer_token = "' "$config_path" | sed -E 's/.*"([^"]+)".*/\1/' | head -n1)"

if [[ -z "$base_url" ]]; then
  echo "base_url not found in $config_path" >&2
  exit 1
fi

if [[ -z "$bearer_token" ]]; then
  echo "experimental_bearer_token not found in $config_path" >&2
  exit 1
fi

mapfile -t model_ids < <(
  curl -fsS -H "Authorization: ${bearer_token}" "${base_url%/}/models" \
    | jq -r '.data[].id' \
    | sort -u
)

resolve_family_model() {
  local family="$1"
  local pattern=""
  case "$family" in
    deepseek)
      pattern='(^|[/-])deepseek'
      ;;
    minimax)
      pattern='(^|[/-])minimax'
      ;;
    kimi)
      pattern='(^|[/-])kimi'
      ;;
    claude-haiku)
      pattern='claude-haiku'
      ;;
    claude-sonnet)
      pattern='claude-sonnet'
      ;;
    glm)
      pattern='(^|[/-])glm'
      ;;
    *)
      echo "unknown family: $family" >&2
      return 1
      ;;
  esac

  printf '%s\n' "${model_ids[@]}" \
    | rg "$pattern" \
    | sort -u \
    | tail -n1
}

for family in "$@"; do
  model_id="$(resolve_family_model "$family")"
  if [[ -z "$model_id" ]]; then
    echo "no live model found for family: $family" >&2
    exit 1
  fi
  printf '%s\n' "$model_id"
done
