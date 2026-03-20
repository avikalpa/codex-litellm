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
  - `vercel/claude-haiku-4.5`: pass on the explicit restyle prompt, but still needs broader fixture coverage
  - `vercel/glm-5-turbo`: failed on the focused rerun after hitting retry/rate-limit noise before a repo diff
  - `vercel/kimi-k2.5`: failed by finalizing without a repo diff
- separately tracked blocked route:
  - `vercel/deepseek-v3.2-thinking`: failed on LiteLLM `/responses` tool-follow-up handling

## Release Read
- `/responses` remains the default forward path.
- DeepSeek remains a known blocker on that path.
- MiniMax is the current release gate and current best default route.
- Claude Haiku has moved up into the promising bench tier on the explicit restyle prompt, but it is still not a default recommendation.
- Kimi and GLM stay in the active bench as non-default routes that still need more work.
- The bench prompt is now explicit enough to force a measurable button restyle instead of inviting “already done” false passes.

## Evidence
- passing MiniMax smoke on `0.116.0`: current `mini-web` run recorded in local `logs/`
- passing Claude Haiku smoke on the explicit prompt: current `mini-web` run recorded in local `logs/`
- current Kimi failure: latest `mini-web` run recorded in local `logs/`
- current DeepSeek failure: latest `mini-web` run recorded in local `logs/`
- current GLM failure with retry/rate-limit noise: latest `mini-web` run recorded in local `logs/`

## Remaining Work
- let the in-flight `0.116.0` release complete on GitHub Actions
- keep DeepSeek tracked as a blocked `/responses` route until the bridge bug is fixed
- extend the refreshed explicit-prompt bench to `python-cli` and a heavier repo so Claude Haiku and MiniMax are not only validated on `mini-web`

## Handoff Rule
Do not release or publish from any older base.
