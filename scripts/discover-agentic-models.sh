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
  grok-fast

Options:
  --profile <dir>   Profile directory containing config.toml and .env
  --config <file>   Explicit config.toml path
  --env-file <file> Explicit .env file path

If no config path is provided, the script uses $CODEX_HOME/config.toml, then
falls back to ~/.codex/config.toml.
EOF
}

config_path=""
env_path=""
profile_dir=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      profile_dir="$2"
      config_path="$2/config.toml"
      env_path="$2/.env"
      shift 2
      ;;
    --config)
      config_path="$2"
      shift 2
      ;;
    --env-file)
      env_path="$2"
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

if [[ -z "$profile_dir" && -n "${CODEX_HOME:-}" ]]; then
  profile_dir="$CODEX_HOME"
fi

if [[ -z "$config_path" ]]; then
  if [[ -n "$profile_dir" ]]; then
    config_path="$profile_dir/config.toml"
  else
    config_path="$HOME/.codex/config.toml"
  fi
fi

if [[ -z "$env_path" ]]; then
  if [[ -n "$profile_dir" ]]; then
    env_path="$profile_dir/.env"
  else
    env_path="$HOME/.codex/.env"
  fi
fi

if [[ ! -f "$config_path" ]]; then
  echo "config.toml not found: $config_path" >&2
  exit 1
fi

read_toml_value() {
  local file="$1"
  local key="$2"
  awk -v key="$key" '
    /^\[model_providers\.litellm\]$/ { in_section=1; next }
    /^\[/ { in_section=0 }
    in_section && $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
      match($0, /"[^"]+"/)
      if (RSTART > 0) {
        print substr($0, RSTART + 1, RLENGTH - 2)
        exit
      }
    }
  ' "$file"
}

read_env_value() {
  local file="$1"
  local key="$2"
  if [[ -n "${!key:-}" ]]; then
    printf '%s\n' "${!key}"
    return
  fi
  if [[ -f "$file" ]]; then
    awk -F= -v key="$key" '
      $1 == key {
        value = substr($0, index($0, "=") + 1)
        gsub(/^["'\'']|["'\'']$/, "", value)
        print value
        exit
      }
    ' "$file"
  fi
}

base_url="$(read_toml_value "$config_path" "base_url")"
env_key="$(read_toml_value "$config_path" "env_key")"
bearer_token="$(read_toml_value "$config_path" "experimental_bearer_token")"

if [[ -z "$base_url" ]]; then
  base_url="$(read_env_value "$env_path" "LITELLM_BASE_URL")"
fi

if [[ -z "$bearer_token" && -n "$env_key" ]]; then
  bearer_token="$(read_env_value "$env_path" "$env_key")"
fi

if [[ -z "$bearer_token" ]]; then
  bearer_token="$(read_env_value "$env_path" "LITELLM_API_KEY")"
fi

if [[ -z "$base_url" ]]; then
  echo "LiteLLM base_url not found in $config_path or $env_path" >&2
  exit 1
fi

if [[ -z "$bearer_token" ]]; then
  echo "LiteLLM API key not found in $config_path, $env_path, or environment" >&2
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
    grok-fast)
      pattern='grok.*fast.*reasoning|grok.*code.*fast'
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
