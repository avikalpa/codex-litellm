## Telemetry Overview

Our LiteLLM fork introduces two telemetry pipelines that are disabled by default upstream:

```toml
[telemetry]
enabled = true
dir = "logs"
max_total_bytes = 104857600

[telemetry.logs.tui]
file = "codex-tui.log"

[telemetry.logs.session]
enabled = true
file = "codex-litellm-session.jsonl"
```

1. **`codex-litellm-debug-telemetry`**  
   - Purpose: high-fidelity tracing of onboarding, model selection, header state, and network overrides.  
   - Output: newline-delimited JSON files in `${CODEX_HOME}/logs/` (timestamped on launch).  
   - Configuration: toggle via the `[telemetry] enabled` switch or `[telemetry.logs.debug]` table in `config.toml`.  
   - Hooks: instrumented inside the TUI (`chatwidget`, onboarding) and core client (request dispatch / retries).

2. **`codex-litellm-model-session-telemetry`**  
   - Purpose: aggregate token usage, request counts, and model slugs for `/status` and future billing insights.  
   - Output: session-scoped JSON files in `${CODEX_HOME}/logs/` (default file `codex-litellm-session.jsonl`).  
   - Configuration: `[telemetry] enabled` plus per-log settings in `[telemetry.logs.session]` control behaviour.  
   - Hooks: integrated within `chat_completions`, the exec runner, and TUI turn lifecycle.

### Key Behaviours

- Both telemetry modules honour a shared `telemetry_dir` setting; when omitted we default to `${CODEX_HOME}/logs`.  
- `codex-litellm-debug-telemetry` records structured spans:
  - `onboarding.*` — credential entry, preset download, model/effort confirmation.
  - `model_selection.*` — `/model` popup lifecycle (preset source, reasoning choices, persistence).
  - `chatwidget.header.*` — header refresh pipeline, override reconciliation.
- `display.*` — high-level TUI rendering flow (user submissions, status headers, aggregated responses).
- Recent additions:
- `history.task_complete_event` / `history.task_complete_message` whenever the backend signals a turn wrap-up (captures the final assistant snippet if present).
- `history.final_separator_pending` / `history.final_separator_inserted` to track when the “Worked for …” banner is queued and committed (includes the elapsed wall-clock time).
- `status.token_usage_update` each time `/status` counters refresh (prompt/completion/total tokens).
- `model.request` / `model.response` — effective slug, stream mode, retry cause.
- `history.agent_message_suppressed` when LiteLLM’s autoprompt chatter is filtered out in the TUI so we can correlate “silent” assistant turns with the buffered fallback logic.
- `oss_buffered.request_elapsed_ms` + `oss_buffered.request_timeout` to record how long each buffered LiteLLM call waited (per-attempt 45 s cap) before returning or timing out. These entries live in `logs/oss-exec-trace.log` and make it obvious when the server stalls despite a healthy network.
- `history.buffered_turn_complete` (background event string “Buffered turn complete after …s”) emitted the moment the buffered loop exits, allowing the TUI to drop the “Working…” indicator without waiting for user input.
- Session telemetry files are keyed by the session UUID to simplify resume flows.
- Set `[telemetry] max_total_bytes` (default 100 MiB) to prune the oldest non-active log files when the directory grows beyond the budget. Use `0` to disable pruning entirely.
- To disable telemetry entirely, set `[telemetry] enabled = false` (this suppresses both debug and session writers) or launch with `--no-telemetry`.
- CLI overrides: `codex --telemetry` / `--no-telemetry`, `codex exec --telemetry` / `--no-telemetry`.

See `config.toml` for example settings, and `/status` for a live view of aggregated session data.

### `trace/telemetry.py` — dtrace-style session slicing

A new helper CLI lives under `trace/telemetry.py` and provides a programmable
front-end over the session JSONL logs. It eliminates the need to copy/paste TUI
transcripts into `oss-tui-run.txt`—run it locally instead.

Key commands:

```bash
# List the latest sessions under ~/.codex-litellm-debug (override via CODEX_TRACE_HOME or --home)
python trace/telemetry.py list --limit 5

# Inspect only the reasoning/status events for a particular session UUID
python trace/telemetry.py events --session 019a7c5e-... --types event_msg --contains "Continuing automatically" --header

# Summarize event counts (reasoning vs assistant replies) to spot duplicate reasoning bugs
python trace/telemetry.py summary --session 019a7c5e-...
```

Options:

- `--home`: point at any CODEX_HOME to read its `sessions/**.jsonl` tree.
- `--types` and `--contains`: filter down to specific telemetry sources (e.g.,
  `agent_reasoning_raw_content`, `background_event`, `response_item`).
- `--json`: emit raw JSON for downstream tooling; otherwise we show a compact
  timestamp/type preview trimmed to `--width` columns.

Because it only reads local files the tool works without network access; bake it
into every debugging loop so we capture the “why” alongside the “what”.

Environment notes:

- The helper only uses the Python standard library, but if you prefer an isolated
  interpreter, create `trace/venv` (already gitignored) with `uv venv trace/venv`
  and run it via `trace/venv/bin/python trace/telemetry.py …`. Use `uv pip …`
  inside that venv whenever we eventually add third-party probes.
