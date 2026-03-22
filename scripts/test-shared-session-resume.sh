#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CODEX_RS_DIR="$ROOT_DIR/codex/codex-rs"
CODEX_BIN="$CODEX_RS_DIR/target/debug/codex"
LITELLM_BIN="$CODEX_RS_DIR/target/debug/codex-litellm"
WORKDIR="$ROOT_DIR"
TMP_UPSTREAM_DIR=""

bootstrap_patched_checkout() {
  local base_version pinned_tag
  base_version=$(node -p "require('$ROOT_DIR/package.json').codexLitellm.baseVersion")
  pinned_tag="rust-v${base_version}"

  TMP_UPSTREAM_DIR=$(mktemp -d)
  git clone --filter=blob:none https://github.com/openai/codex.git "$TMP_UPSTREAM_DIR/codex" >/dev/null 2>&1
  git -C "$TMP_UPSTREAM_DIR/codex" fetch --tags --quiet
  git -C "$TMP_UPSTREAM_DIR/codex" checkout "$pinned_tag" --quiet
  git -C "$TMP_UPSTREAM_DIR/codex" apply --whitespace=nowarn "$ROOT_DIR/stable-tag.patch"

  CODEX_RS_DIR="$TMP_UPSTREAM_DIR/codex/codex-rs"
  CODEX_BIN="$CODEX_RS_DIR/target/debug/codex"
  LITELLM_BIN="$CODEX_RS_DIR/target/debug/codex-litellm"
}

if ! rg -q 'name = "codex-litellm"' "$CODEX_RS_DIR/cli/Cargo.toml"; then
  bootstrap_patched_checkout
fi

cd "$CODEX_RS_DIR"
cargo build --bin codex --bin codex-litellm >/dev/null

tmpdir=$(mktemp -d)
cleanup() {
  if [[ -n "${server_pid:-}" ]]; then
    kill "$server_pid" >/dev/null 2>&1 || true
    wait "$server_pid" 2>/dev/null || true
  fi
  if [[ -n "$TMP_UPSTREAM_DIR" ]]; then
    rm -rf "$TMP_UPSTREAM_DIR"
  fi
  rm -rf "$tmpdir"
}
trap cleanup EXIT

cat >"$tmpdir/server.py" <<'PY'
import os
from http.server import BaseHTTPRequestHandler, HTTPServer

REQUEST_LOG = os.environ["REQUEST_LOG"]
RESPONSE_BODY = (
    'event: response.created\n'
    'data: {"type":"response.created","response":{"id":"resp-1","object":"response","status":"in_progress"}}\n\n'
    'event: response.output_item.added\n'
    'data: {"type":"response.output_item.added","output_index":0,"item":{"id":"msg-1","type":"message","status":"in_progress","role":"assistant","content":[]}}\n\n'
    'event: response.output_text.delta\n'
    'data: {"type":"response.output_text.delta","item_id":"msg-1","output_index":0,"content_index":0,"delta":"hi"}\n\n'
    'event: response.output_item.done\n'
    'data: {"type":"response.output_item.done","output_index":0,"item":{"id":"msg-1","type":"message","status":"completed","role":"assistant","content":[{"type":"output_text","text":"hi"}]}}\n\n'
    'event: response.completed\n'
    'data: {"type":"response.completed","response":{"id":"resp-1","object":"response","status":"completed","output":[{"id":"msg-1","type":"message","status":"completed","role":"assistant","content":[{"type":"output_text","text":"hi"}]}]}}\n\n'
)

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith("/v1/models"):
            body = (
                '{"object":"list","data":['
                '{"id":"gpt-5.4","object":"model"},'
                '{"id":"vercel/minimax-m2.7-highspeed","object":"model"}'
                ']}'
            )
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(body.encode())
            return

        self.send_response(404)
        self.end_headers()

    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0") or "0")
        raw = self.rfile.read(length).decode()
        with open(REQUEST_LOG, "a", encoding="utf-8") as fh:
            fh.write(raw)
            fh.write("\n---\n")

        if self.path != "/v1/responses":
            self.send_response(404)
            self.end_headers()
            return

        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.end_headers()
        self.wfile.write(RESPONSE_BODY.encode())

    def log_message(self, *args):
        pass

HTTPServer(("127.0.0.1", 8767), Handler).serve_forever()
PY

export REQUEST_LOG="$tmpdir/requests.log"
python3 "$tmpdir/server.py" >/dev/null 2>&1 &
server_pid=$!
sleep 1

write_config() {
  local home_root="$1"
  mkdir -p "$home_root/.codex"
  cat >"$home_root/.codex/config.toml" <<'EOF'
model = "gpt-5.4"

[model_providers.litellm]
name = "LiteLLM"
base_url = "http://127.0.0.1:8767/v1"
env_key = "LITELLM_API_KEY"
wire_api = "responses"

[profiles.codex-litellm]
model = "vercel/minimax-m2.7-highspeed"
model_provider = "litellm"
EOF
}

find_session_path() {
  local sessions_dir="$1"
  local marker="$2"
  rg -l --glob '*.jsonl' "$marker" "$sessions_dir" | head -n1
}

run_case() {
  local case_name="$1"
  local seed_bin="$2"
  local seed_provider="$3"
  local seed_model="$4"
  local resume_bin="$5"
  local resume_provider="$6"
  local resume_model="$7"

  local home_root="$tmpdir/$case_name-home"
  local seed_out="$tmpdir/$case_name-seed.out"
  local resume_out="$tmpdir/$case_name-resume.out"
  local seed_marker="seed-${case_name}"
  local resume_marker="resume-${case_name}"
  local sessions_dir
  local seed_path
  local resumed_path

  write_config "$home_root"
  sessions_dir="$home_root/.codex/sessions"
  : >"$REQUEST_LOG"

  HOME="$home_root" \
  OPENAI_API_KEY=dummy-openai-key \
  OPENAI_BASE_URL=http://127.0.0.1:8767/v1 \
  LITELLM_API_KEY=dummy-litellm-key \
  "$seed_bin" exec --skip-git-repo-check -C "$WORKDIR" "$seed_marker" >"$seed_out" 2>&1

  grep -q "provider: $seed_provider" "$seed_out"
  grep -q "\"model\":\"$seed_model\"" "$REQUEST_LOG"

  seed_path=$(find_session_path "$sessions_dir" "$seed_marker")
  [[ -n "$seed_path" ]]

  : >"$REQUEST_LOG"

  HOME="$home_root" \
  OPENAI_API_KEY=dummy-openai-key \
  OPENAI_BASE_URL=http://127.0.0.1:8767/v1 \
  LITELLM_API_KEY=dummy-litellm-key \
  "$resume_bin" exec --skip-git-repo-check -C "$WORKDIR" resume --last --all "$resume_marker" >"$resume_out" 2>&1

  grep -q "provider: $resume_provider" "$resume_out"
  grep -q "model: $resume_model" "$resume_out"
  grep -q "^hi$" "$resume_out"
  if grep -q "Consider switching back to" "$resume_out"; then
    echo "unexpected cross-provider model warning in $case_name" >&2
    cat "$resume_out" >&2
    exit 1
  fi
  grep -q "\"model\":\"$resume_model\"" "$REQUEST_LOG"

  resumed_path=$(find_session_path "$sessions_dir" "$resume_marker")
  [[ -n "$resumed_path" ]]
  [[ "$seed_path" == "$resumed_path" ]]
}

run_case \
  openai-to-litellm \
  "$CODEX_BIN" \
  openai \
  gpt-5.4 \
  "$LITELLM_BIN" \
  litellm \
  vercel/minimax-m2.7-highspeed

run_case \
  litellm-to-openai \
  "$LITELLM_BIN" \
  litellm \
  vercel/minimax-m2.7-highspeed \
  "$CODEX_BIN" \
  openai \
  gpt-5.4

echo "shared ~/.codex resume smoke OK"
