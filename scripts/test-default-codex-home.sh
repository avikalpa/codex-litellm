#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CODEX_RS_DIR="$ROOT_DIR/codex/codex-rs"
BIN="$CODEX_RS_DIR/target/debug/codex-litellm"
WORKDIR="$CODEX_RS_DIR"

cd "$CODEX_RS_DIR"
cargo build --bin codex-litellm >/dev/null

tmpdir=$(mktemp -d)
cleanup() {
  if [[ -n "${server_pid:-}" ]]; then
    kill "$server_pid" >/dev/null 2>&1 || true
    wait "$server_pid" 2>/dev/null || true
  fi
  rm -rf "$tmpdir"
}
trap cleanup EXIT

cat >"$tmpdir/server.py" <<'PY'
import json
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

HTTPServer(("127.0.0.1", 8766), Handler).serve_forever()
PY

export REQUEST_LOG="$tmpdir/requests.log"
python3 "$tmpdir/server.py" >/dev/null 2>&1 &
server_pid=$!
sleep 1

run_case() {
  local case_name="$1"
  local home_root="$tmpdir/$case_name-home"
  local out_file="$tmpdir/$case_name.out"
  mkdir -p "$home_root/.codex"

  case "$case_name" in
    config)
      cat >"$home_root/.codex/config.toml" <<'EOF'
model = "vercel/minimax-m2.5"
model_provider = "litellm"

[model_providers.litellm]
name = "LiteLLM"
base_url = "http://127.0.0.1:8766/v1"
env_key = "PATH"
wire_api = "responses"
EOF
      HOME="$home_root" "$BIN" exec --skip-git-repo-check -C "$WORKDIR" "hello?" >"$out_file" 2>&1
      ;;
    dotenv)
      cat >"$home_root/.codex/.env" <<'EOF'
LITELLM_BASE_URL=http://127.0.0.1:8766/v1
LITELLM_API_KEY=dummy-key
EOF
      HOME="$home_root" "$BIN" exec --skip-git-repo-check --model vercel/minimax-m2.5 -C "$WORKDIR" "hello?" >"$out_file" 2>&1
      ;;
    *)
      echo "Unknown case: $case_name" >&2
      exit 1
      ;;
  esac

  grep -q "provider: litellm" "$out_file"
  grep -q "^hi$" "$out_file"
}

run_case config
run_case dotenv

grep -q '"model":"vercel/minimax-m2.5"' "$REQUEST_LOG"

echo "default ~/.codex smoke OK"
