# Polish

## Model Experience
- [x] We should not require a pre-existing `config.toml`. During the first session the onboarding flow must prompt for the LiteLLM endpoint and API key, mirroring upstream Codex.
- [x] `/logout` followed by a restart should re-run the credentials onboarding flow so the user can change endpoint/API key without manual edits.
- [x] The onboarding sequence should include the LiteLLM model selector between credentials and approvals, seeded from the latest `/v1/models` response.
- [x] `/model` must offer the full two-stage selector (model list, then reasoning effort) and persist the choice for the current and future sessions. The list should contain only live LiteLLM presets—no legacy test slugs like `gpt-oss-120b-litellm`.

## Session Lifecycle & Context
- Current state: Probably a lot has already been implemented just not documented here. Check first.
- [x] When quitting via `/quit`, show the resumable command (e.g. `codex resume <UUID>`) exactly like upstream.
- [x] Default the session context window to 130k tokens (configurable via `codex.toml`) and auto-compact history when a conversation exceeds the limit.
- [x] On resume, detect history that exceeds the configured context window and prompt the user to compact or abort.
- [x] Display the combined version string (`upstream_tag+lit_commit`) everywhere the CLI surfaces version info.

## Status & UI
- Current state: Probably a lot has already been implemented just not documented here. Check first.
- [x] `/status` should surface LiteLLM usage stats (tokens in/out, context consumption, rate limit notices) and handle “no data yet” cases gracefully.
- [x] The TUI status/context indicators must reflect the correct context % and reasoning summary (no perpetually 100% bars).
- [x] Retain the customized ASCII onboarding welcome screen with LiteLLM-specific guidance.

## Telemetry
- Current state: telemetry logs are routed beneath `$CODEX_HOME/logs/` with per-crate toggles; session usage is recorded through `codex-litellm-model-session-telemetry` and exposed via `/status`; debug traces funnel through `codex-litellm-debug-telemetry`.
- Next improvements to explore:
  - [x] Add log rotation or size-based pruning so `$CODEX_HOME/logs` does not grow unbounded.
  - [x] Record structured markers for onboarding/model selection events to speed up future regressions.
  - [x] Consider a lightweight CLI switch (e.g. `--no-telemetry`) to disable both debug and session logging for sensitive environments.

## Model Response Fixes
- Caveats: Check for docs/PROJECT_SUMMARY.md for litellm nuances (eg. streaming responses do not work, always use non-streaming as a fix)
- [x] Ensure every LiteLLM request and response is captured by `codex-litellm-debug-telemetry`, including provider-specific variants.
- [x] Log which display element in the TUI gets triggered by request or response.
- [x] Normalize rendered responses across providers so the TUI displays assistant output consistently (watch for streamed vs. buffered payloads).
- [x] Keep the conversation context in sync with streamed tool calls and reasoning sections across providers.

## Publishing
- We should push to github for github actions workflow. Add workflows to publish package to openwrt and termux in addition to npmjs workflow.
