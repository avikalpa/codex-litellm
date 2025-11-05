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
- [x] Push to GitHub so the Actions release workflow runs (artifacts + npm/OpenWrt/Termux).
- [x] Change the project license to Apache-2.0 to match upstream.
- [x] Bundle `LICENSE` and `NOTICE` inside every release artifact (tarballs, OpenWrt `.ipk`, Termux `.deb`).
- [x] Refresh README copy to reflect the new licensing stance and distribution notes.
- [x] Capture our release/compliance playbook in `docs/COMPLIANCE.md`, keep it general-purpose, and link it from `AGENTS.md` so future sweeps follow the same checklist.
- [x] Publish the inaugural GitHub Actions release to npm under the `codex-litellm` package name.
- [x] Stage Linux (x64 + arm64) and macOS (x64 + arm64) desktop artifacts first, along with the npm release; keep the other matrix jobs disabled until these succeed, then re-enable OpenWrt/Termux in a follow-up sweep.
- [ ] Package and push OpenWrt builds covering GL-iNET Flint-2 (`aarch64_generic`) and OpenWrt One (`x86_64`) once the desktop/npm release is verified; stage additional arches (ipq807x, mt7621) when toolchains are reproducible.
- [ ] Package and publish Termux binaries for `aarch64` and `x86_64` after the primary release lands, then investigate extending support to `armv7`/`i686`.
- [ ] Re-run the npm install + LiteLLM exec sanity test after the `v0.55.0+...` release assets publish (`npm i -g @avikalpa/codex-litellm`; `codex-litellm --model vercel/gpt-oss-120b exec "who are you"`).
