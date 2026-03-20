#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/run-agentic-model-smoke.sh --fixture <fixture> --model <slug> [options]

Options:
  --workspace <dir>   Workspace directory (default: test-workspace)
  --profile <dir>     Optional CODEX_HOME profile
  --prompt <text>     Override the default prompt for the fixture
EOF
}

fixture=""
model=""
workspace="test-workspace"
profile=""
prompt=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fixture)
      fixture="$2"
      shift 2
      ;;
    --model)
      model="$2"
      shift 2
      ;;
    --workspace)
      workspace="$2"
      shift 2
      ;;
    --profile)
      profile="$2"
      shift 2
      ;;
    --prompt)
      prompt="$2"
      shift 2
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$fixture" || -z "$model" ]]; then
  usage
  exit 1
fi

case "$fixture" in
  calibre-web|mini-web)
    default_prompt="change every button and button-like input in the repository to use a diagonal gradient from #195c53 to #d17a2d, a 999px pill radius, 14px 24px padding, and a stronger hover shadow. Make the repo edit directly and finish after the edit. Do not ask for permission."
    ;;
  python-cli)
    default_prompt="add a --verbose option to the CLI, update the README usage section, and add or update a test for it. Just do it."
    ;;
  *)
    echo "Unknown fixture for default prompt: $fixture" >&2
    exit 1
    ;;
esac

if [[ -z "$prompt" ]]; then
  prompt="$default_prompt"
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
safe_model="${model//\//_}"
log_path="$repo_root/logs/model-test-${safe_model}-${fixture}-$(date +%Y%m%d-%H%M%S).log"

"$repo_root/scripts/setup-test-repo.sh" --refresh "$fixture" "$repo_root/$workspace"

cmd=("$repo_root/codex/codex-rs/target/debug/codex" exec "$prompt" --model "$model" --skip-git-repo-check)

echo "fixture=$fixture"
echo "model=$model"
echo "workspace=$workspace"
echo "log=$log_path"

validate_fixture_result() {
  local fixture_name="$1"
  case "$fixture_name" in
    python-cli)
      local changed
      changed="$(git diff --name-only)"
      for required in README.md src/fixture_cli/cli.py tests/test_cli.py; do
        if ! grep -qx "$required" <<<"$changed"; then
          echo "Smoke test failed: python-cli fixture requires a diff in $required." >&2
          return 3
        fi
      done
      ;;
  esac
}

set +e
(
  cd "$repo_root/$workspace"
  if [[ -n "$profile" ]]; then
    CODEX_HOME="$profile" "${cmd[@]}"
  else
    "${cmd[@]}"
  fi
  echo
  echo "git diff --stat"
  git diff --stat
  if git diff --quiet --exit-code; then
    echo "Smoke test failed: model returned without making a repo edit." >&2
    exit 2
  fi
  validate_fixture_result "$fixture"
) | tee "$log_path"
cmd_status=${PIPESTATUS[0]}
set -e
exit "$cmd_status"
