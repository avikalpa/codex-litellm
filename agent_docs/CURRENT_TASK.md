# Current Task — 0.116.0 Upstream Refresh

Last updated: 2026-03-20

## TL;DR
- `codex/` is aligned to upstream `rust-v0.116.0` at commit `38771c90`.
- Root metadata is aligned to the same base:
  - `package.json.version = 0.116.0`
  - `package.json.codexLitellm.baseVersion = 0.116.0`
  - `package.json.codexLitellm.upstreamCommit = 38771c90`
- `stable-tag.patch` has been regenerated from `rust-v0.116.0`.
- `cargo build --locked --bin codex` passes on this tree.

## What Changed In The 0.116.0 Port
- carried forward the LiteLLM `/responses` runtime path
- kept tool normalization for LiteLLM function-style tool payloads
- kept transient follow-up instructions instead of persisting them into conversation history
- kept retry-state reset / websocket-to-http recovery logic for LiteLLM stream failures
- kept the post-edit read-only shell guard
- kept curated agentic-model filtering and metadata tuning
- added tolerance for out-of-order streamed deltas so debug runs no longer panic on `OutputTextDelta without active item`

## Current Validation State
- required debug build: pass
- current live `mini-web` smoke on the gateway-discovered MiniMax route with the explicit restyle prompt: pass
- current active `mini-web` research matrix:
  - `vercel/minimax-m2.7-highspeed`: pass
  - `vercel/claude-haiku-4.5`: pass
  - `vercel/glm-5-turbo`: failed on the focused rerun after hitting retry/rate-limit noise before a repo diff
  - `vercel/kimi-k2.5`: failed by finalizing without a repo diff
- current watchlist reruns:
  - `vercel/grok-4.20-reasoning-beta`: pass on the explicit restyle prompt, but still needs broader fixture coverage
  - `vercel/gemini-3.1-pro-preview`: made the right edit diff on the explicit prompt, but stalled too long after the edit to count as clean green
- separately tracked blocked route:
  - `vercel/deepseek-v3.2-thinking`: failed on LiteLLM `/responses` tool-follow-up handling
- current strict `python-cli` gate:
  - `vercel/minimax-m2.7-highspeed`: pass
  - `vercel/claude-haiku-4.5`: pass
  - `vercel/kimi-k2.5`: pass
  - `vercel/grok-4.20-reasoning-beta`: failed under rate-limit pressure before a qualifying diff
  - `vercel/gemini-3.1-pro-preview`: timed out after doing the right class of work, but still did not complete cleanly enough to pass
  - `vercel/glm-5-turbo`: failed after retry/rate-limit pressure before a qualifying diff
- initial heavier `calibre-web` probe:
  - `vercel/minimax-m2.7-highspeed`: failed under route pressure with no clean diff on the latest heavy probe
  - `vercel/glm-5-turbo`: failed under the same class of retry or 429 pressure
  - broader heavy-repo batch was stopped early because the route signal had already become clear enough for the current README research report

## Release Read
- `/responses` remains the default forward path.
- DeepSeek remains a known blocker on that path.
- MiniMax is the current release gate and current best default route.
- Claude Haiku now has stronger evidence and is the current best cheaper second option after MiniMax.
- Kimi is now split rather than simply weak: it fails the UI fixture but clears the stricter procedural CLI task.
- GLM stays in the active bench as a non-default route that still needs more work.
- Gemini 3.1 Pro Preview and Grok 4.20 are back in the watchlist lane and should continue to be tested instead of disappearing from the bench.
- The bench prompt is now explicit enough to force a measurable button restyle instead of inviting “already done” false passes.
- The `python-cli` fixture now has stricter pass criteria: CLI file, README, and test file must all change.
- Heavy-repo evidence is now starting to show the boundary between model capability and route or harness stress, especially around retries, rate limits, and clean post-edit finalization.

## Evidence
- passing MiniMax smoke on `0.116.0`: current `mini-web` run recorded in local `logs/`
- passing Claude Haiku smoke on the explicit prompt: current `mini-web` and strict `python-cli` runs recorded in local `logs/`
- passing MiniMax strict `python-cli` smoke: current run recorded in local `logs/`
- passing Kimi strict `python-cli` smoke: current run recorded in local `logs/`
- passing Grok 4.20 smoke on the explicit prompt: current `mini-web` run recorded in local `logs/`
- current Gemini 3.1 Pro Preview rerun with edit-but-stall behavior: current `mini-web` run recorded in local `logs/`
- current Kimi failure: latest `mini-web` run recorded in local `logs/`
- current DeepSeek failure: latest `mini-web` run recorded in local `logs/`
- current GLM failure with retry/rate-limit noise: latest `mini-web` run recorded in local `logs/`
- current GLM, Grok, and Gemini strict `python-cli` failures: current runs recorded in local `logs/`
- current heavy-repo stress failures: current runs recorded in local `logs/`

## Remaining Work
- let the in-flight `0.116.0` release complete on GitHub Actions
- keep DeepSeek tracked as a blocked `/responses` route until the bridge bug is fixed
- finish the heavier `calibre-web` matrix cleanly for Claude Haiku, Grok, Gemini, and Kimi once route noise is lower
- use the heavier-repo results to decide whether the next harness work should focus on retry budgeting, stronger finalize steering, or both

## Handoff Rule
Do not release or publish from any older base.
