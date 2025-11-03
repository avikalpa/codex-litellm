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
  - `model.request` / `model.response` — effective slug, stream mode, retry cause.
- Session telemetry files are keyed by the session UUID to simplify resume flows.
- Set `[telemetry] max_total_bytes` (default 100 MiB) to prune the oldest non-active log files when the directory grows beyond the budget. Use `0` to disable pruning entirely.
- To disable telemetry entirely, set `[telemetry] enabled = false` (this suppresses both debug and session writers) or launch with `--no-telemetry`.
- CLI overrides: `codex --telemetry` / `--no-telemetry`, `codex exec --telemetry` / `--no-telemetry`.

See `config.toml` for example settings, and `/status` for a live view of aggregated session data.
