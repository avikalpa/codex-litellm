# Codex LiteLLM Exclusive Features

Codex LiteLLM layers additional observability and configuration controls on
top of the upstream CLI. These mechanics are opt-in for the stock client and
therefore live entirely inside this patchset.

## Telemetry directory and configuration

All Codex LiteLLM telemetry now lives under `$(CODEX_HOME)/logs`. The path and
per-log behaviour are controlled via a new `[telemetry]` section in
`config.toml`:

```toml
[telemetry]
enabled = true                       # set false to disable all telemetry writers
dir = "logs"                         # defaults to CODEX_HOME/logs
max_total_bytes = 104857600          # prune oldest non-active logs when over 100 MiB

[telemetry.logs.tui]
file = "codex-tui.log"               # standard tracing output from codex-tui

[telemetry.logs.debug]
enabled = true                       # disable to skip high-volume debug traces
# file is generated dynamically (YYYYMMDD-HHMMSS.log) when left unspecified

[telemetry.logs.session]
file = "codex-litellm-session.jsonl" # per-turn LiteLLM usage snapshots
```

Any additional entries placed under `telemetry.logs.*` are preserved and can be
consumed by downstream tooling.

When `max_total_bytes` is set (the default), Codex prunes the oldest files in
the telemetry directory—skipping any log that is currently configured as an
active target—until the total size falls below the threshold. Set the value to
`0` to disable pruning entirely.

Runtime overrides:
- `codex --telemetry` / `codex --no-telemetry`
- `codex exec --telemetry` / `codex exec --no-telemetry`

The flags above map to the new `[telemetry] enabled` knob without requiring a
config edit. CLI `-c telemetry.enabled=<bool>` overrides remain available.

### Debug event log

When `telemetry.logs.debug` is enabled (the default), `codex-tui` installs a
dedicated tracing layer that streams high-fidelity events (onboarding steps,
header redraws, `/model` interactions, display updates, etc.) into a timestamped
file inside the telemetry directory. The CLI prints the destination on startup:

```
telemetry: recording debug events to /path/to/.codex/logs/20251102-125342.log
```

This log is invaluable when debugging TUI regressions because it captures the
exact render and event sequence without forwarding the full stdout stream.

### LiteLLM session telemetry

The new `codex-litellm-model-session-telemetry` crate aggregates LiteLLM usage
on a per-session basis. Each turn records the model slug, reasoning effort, and
token counts (prompt/completion/reasoning). The data set is:

* persisted in-memory for quick access,
* exposed on `/status` as a “LiteLLM usage” card, and
* streamed to `telemetry.logs.session` as line-delimited JSON when a log file
  is configured.

Example log entry:

```json
{
  "ts": "2025-11-02T12:54:11.238Z",
  "session_id": "019a44bc-39c3-7159-bb96-ecb9c5a1de11",
  "model": "vercel/minimax-m2",
  "reasoning_effort": "medium",
  "prompt_tokens": 132,
  "completion_tokens": 284,
  "reasoning_tokens": 0,
  "total_tokens": 416
}
```

## Context-length override

LiteLLM deployments often provide smaller context windows than the upstream
GPT-5 defaults. Codex LiteLLM therefore ships with a 130 k token baseline and
introduces a user-facing `context_length` key in `config.toml`. The value is an
alias for `model_context_window`, so existing upstream settings continue to
work. When unset, the LiteLLM defaults are applied automatically during
onboarding.

The context limit is honoured by:

* live context usage indicators in the TUI,
* the `/status` card (showing remaining window and per-turn usage), and
* resume-time safeguards that prompt users when a stored session exceeds the
  configured limit, offering to compact or abort the resume.

Together, these features ensure the patched CLI remains observability-first and
ready for the heterogeneity of LiteLLM backends.

## Release Packaging Targets

GitHub Actions now produces additional distribution artifacts whenever a
release is cut:

- **OpenWrt**: `scripts/package-openwrt.sh` wraps the Linux tarballs into
  `.ipk` archives (architectures: `x86_64`, `aarch64_generic`) and publishes
  them alongside the release assets.
- **Termux**: `scripts/package-termux.sh` emits Termux-friendly `.deb` packages
  (architectures: `x86_64`, `aarch64`) that install to
  `data/data/com.termux/files/usr/bin/codex-litellm`.

Both scripts consume the cross-compiled tarballs produced by `build.sh` and can
be executed locally for bespoke packaging workflows.
