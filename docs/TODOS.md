# Immediate todos

- [ ] Use LiteLLM debug logs (`~/.codex-litellm-debug/logs` + session JSONL) to pinpoint why OSS buffered turns stop after reconnaissance—capture the exact request/response pair for the button/pill repro before changing more code.
- [ ] Ensure the “Worked for …” banner replaces the final divider *before* the last assistant message so the TUI never renders a plain `────` footer (minimax still fails to emit the banner + `/quit` footer—see latest telemetry).
- [ ] Mirror upstream "agentic-first" styling by collapsing LiteLLM reasoning chatter (see `logs/formatting-logs-from-another-machine/transcript-minimax-m2-medium.txt`) into a single grey/italic thinking block and suppressing interim "Explored" noise in the TUI.
- [ ] Ensure OSS follow-ups reuse the previously emitted tool-call context verbatim (no re-listing) and document how we compact that history between buffered attempts.
- [ ] Keep the non-agentic fallback text internal so the TUI only shows the final assistant summary; double-check that buffered follow-ups stay silent unless the final attempt fails.
- [ ] Validate the retry/backoff path for buffered OSS calls (network errors, LiteLLM 5xx) and store a repro log in `logs/` once stabilized.
- [ ] Finish the LiteLLM token-usage reconciliation so `/status` and the TUI header report identical context/tokens for minimax sessions; re-test once the scheduler work is done.
- [ ] Restore upstream italic/gray styling for LiteLLM reasoning spans (agentic + buffered) using the minimax transcript (`logs/formatting-logs-from-another-machine/transcript-minimax-m2-medium.txt`) as the baseline; ensure exec-mode reasoning blocks also render in italics.

## Interleaved Models
- [ ] Mirror upstream italic/gray styling for agentic reasoning segments by routing LiteLLM "thinking" spans (baseline `vercel/minimax-m2`, medium reasoning) through the dedicated reasoning display element instead of standard assistant text.
- [ ] Use the stored transcript under `logs/formatting-logs-from-another-machine/` to catalog each reasoning marker and add a regression test/fixture so future minimax-style models continue to render correctly.
- [ ] Verify telemetry + session saving keep interleaved reasoning separate from final answers so copy/export flows no longer duplicate intermediate thoughts.

## Non-Agentic Models
- [x] Keep `vercel/gpt-oss-120b` (medium reasoning) connections alive after the first toolcall during `codex exec "change all buttons in the repository to have a gradient and pill shape"` so the final assistant reply flushes instead of dropping.
- [ ] Instrument the LiteLLM fetch-and-simulate path to detect when non-agentic models stop streaming early, ensure forced follow-ups retain tool access, and add a retry buffer so buffered requests are automatically re-issued on transient failures.
- [ ] Capture a minimal repro log in `logs/` once the fix lands so future regressions are easy to diff.

## Documentation
- [ ] Draft an outline for refreshing `docs/` plus `~/gh/codex-litellm.wiki` so the prose reads like human-written guidance (focus on onboarding, telemetry, and troubleshooting first).
- [ ] Identify which doc sections depend on the upcoming formatting/output fixes so we can stage updates immediately after implementation.
- [ ] Gather before/after snippets that showcase the new rendering + stability work for inclusion in the wiki changelog.

## Economic Analysis


## Exclusive Features
- [ ] Design the `--web` (or equivalent) flag so codex-litellm can run inside LXC/VM sandboxes and expose curated endpoints (e.g., `codex/dev0/gpt-oss-120b`) to Open WebUI for self-hosted agentic chat.
- [ ] Define how the CLI advertises its "listening" mode in `config.toml`, including support for multiple models, per-environment routing, and API key + salt-based token authentication.
- [ ] Document the operational guidance for this mode so teams can reuse existing self-hosted web UIs without shipping a separate Codex web frontend.

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
- [ ] On many headers the program is called OpenAI Codex. Instead it should be called "Codex LiteLLM". This is important I think, becaue under Apache 2 this is a derivative work and quoting OpenAI directly is, I think, improper.

## Telemetry
- Current state: telemetry logs are routed beneath `$CODEX_HOME/logs/` with per-crate toggles; session usage is recorded through `codex-litellm-model-session-telemetry` and exposed via `/status`; debug traces funnel through `codex-litellm-debug-telemetry`.
- Next improvements to explore:
  - [x] Add log rotation or size-based pruning so `$CODEX_HOME/logs` does not grow unbounded.
  - [x] Record structured markers for onboarding/model selection events to speed up future regressions.
  - [x] Consider a lightweight CLI switch (e.g. `--no-telemetry`) to disable both debug and session logging for sensitive environments.
  - [x] Default session usage logging on, keep TUI logs opt-in, and suppress telemetry console banners in TUI/exec.

## Model Response Fixes
- Caveats: Check for docs/PROJECT_SUMMARY.md for litellm nuances (eg. streaming responses do not work, always use non-streaming as a fix)
- [x] Ensure every LiteLLM request and response is captured by `codex-litellm-debug-telemetry`, including provider-specific variants.
- [x] Log which display element in the TUI gets triggered by request or response.
- [x] Normalize rendered responses across providers so the TUI displays assistant output consistently (watch for streamed vs. buffered payloads).
- [x] Keep the conversation context in sync with streamed tool calls and reasoning sections across providers.

## Publishing
- [ ] Current versioning looks like this v0.55.0+2e2063ca+lit2e2063ca. Instead it should look like v0.55.0+cdxl--2e2063ca. In other words the upstream tag+cdxl(denoting codex litellm)--[our short commit hash].
- [x] Push to GitHub so the Actions release workflow runs (artifacts + npm/OpenWrt/Termux).
- [x] Change the project license to Apache-2.0 to match upstream.
- [x] Bundle `LICENSE` and `NOTICE` inside every release artifact (tarballs, OpenWrt `.ipk`, Termux `.deb`).
- [x] Refresh README copy to reflect the new licensing stance and distribution notes.
- [x] Capture our release/compliance playbook in `docs/COMPLIANCE.md`, keep it general-purpose, and link it from `AGENTS.md` so future sweeps follow the same checklist.
- [x] Publish the inaugural GitHub Actions release to npm under the `codex-litellm` package name.
- [x] Stage Linux (x64 + arm64) and macOS (x64 + arm64) desktop artifacts first, along with the npm release; keep the other matrix jobs disabled until these succeed, then re-enable OpenWrt/Termux in a follow-up sweep.
- [ ] Package and push OpenWrt builds covering GL-iNET Flint-2 (`aarch64_generic`) and OpenWrt One (`x86_64`) once the desktop/npm release is verified; stage additional arches (ipq807x, mt7621) when toolchains are reproducible. Release workflow now emits `.ipk` artifacts for both arches—next tagged release should upload them and validate on hardware.
- [ ] Package and publish Termux binaries for `aarch64` and `x86_64` after the primary release lands, then investigate extending support to `armv7`/`i686`. Release workflow now builds the `.deb` artifacts; confirm installation on-device during the follow-up sweep.
- [ ] Confirm the FreeBSD (`freebsd-x64`) and Illumos (`illumos-x64`) tarballs from the release workflow install cleanly and capture any extra setup notes.
- [ ] Smoke-test Windows (`windows-x64`, `windows-arm64`) builds from the release workflow on fresh environments and document any prerequisite installers (VC++ runtimes, etc.).
- [ ] Re-run the npm install + LiteLLM exec sanity test after the `v0.55.0+...` release assets publish (`npm i -g @avikalpa/codex-litellm`; `codex-litellm --model vercel/gpt-oss-120b exec "who are you"`).
- [ ] Fix openwrt build. Openwrt now uses apk like Alpine linux. opkg is deprecated.
- [ ] Why does the debian builds have a hard dependency on termux-tools? As such on debian the package cannot be installed. If the hard dependency is necessary for termux, then we should package debian-unstable builds seperately.
- [ ] Consider an Arch AUR script to be submitted to Arch linux.
- [ ] Mark all releases currently as alpha builds and also add a note in README.md.
- [ ] Currently update checking during start of program hits upstream npm. It should hit our npm for npm builds. For other builds, we need to make a logic that notifies the user how to update it.
