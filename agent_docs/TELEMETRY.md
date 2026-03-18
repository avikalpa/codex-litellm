# Telemetry

Telemetry exists so LiteLLM regressions can be explained from artifacts instead of guesswork.

## Why It Exists
We patch Codex across moving upstream releases, moving LiteLLM releases, and moving provider/model behavior. Without telemetry, failures blur together. With telemetry, we can separate transport issues, tool-loop issues, rendering bugs, and release regressions.

## Main Outputs
- debug log: high-fidelity structured events for request/response and TUI behavior
- session telemetry: per-session model usage and turn metadata
- TUI view log: the lines actually rendered in the interface

These live under `${CODEX_HOME}/logs` when telemetry is enabled.

## Operational Rules
- Use telemetry by default when debugging.
- Treat `logs/codex-tui-stream.jsonl` as the source of truth for TUI rendering bugs.
- Treat session JSONL plus terminal output as the source of truth for exec-mode model failures.
- Extend telemetry before making a blind fix if the current logs do not explain the failure.

## Controls
- `--telemetry` enables telemetry for a run.
- `--no-telemetry` disables it.
- `[telemetry]` settings in `config.toml` control directory and per-log behavior.

## `trace/telemetry.py`
Use `trace/telemetry.py` instead of scrolling raw JSONL.

Useful commands:
```bash
python trace/telemetry.py list --limit 5
python trace/telemetry.py summary --session <uuid>
python trace/telemetry.py events --session <uuid> --header
python trace/telemetry.py tui --session <uuid> --limit 200
```

## Debugging Standard
When behavior is unclear:
1. reproduce with telemetry on
2. capture session/log paths in `agent_docs/CURRENT_TASK.md`
3. explain what the model sent, what we sent back, and what the UI rendered
4. only then patch the code
