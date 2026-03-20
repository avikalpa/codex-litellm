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
- current live `mini-web` smoke on the gateway-discovered MiniMax route: pass
- current wider `mini-web` research matrix:
  - `vercel/minimax-m2.7-highspeed`: pass
  - `vercel/glm-5-turbo`: edit succeeded, but the run still hit retry/rate-limit noise
  - `vercel/kimi-k2.5`: failed by finalizing without a repo diff
  - `vercel/claude-haiku-4.5`: failed by ending without a repo diff after a bad local `apply_patch` assumption
  - `vercel/deepseek-v3.2-thinking`: failed on LiteLLM `/responses` tool-follow-up handling

## Release Read
- `/responses` remains the default forward path.
- DeepSeek remains a known blocker on that path.
- MiniMax is the current release gate and current best default route.
- Kimi, Claude Haiku, and GLM should stay in the bench, not in the default recommendation set.

## Evidence
- passing MiniMax smoke on `0.116.0`: current `mini-web` run recorded in local `logs/`
- current Kimi failure: latest `mini-web` run recorded in local `logs/`
- current DeepSeek failure: latest `mini-web` run recorded in local `logs/`
- current GLM run with edit + retry noise: latest `mini-web` run recorded in local `logs/`
- current Claude Haiku failure: latest `mini-web` run recorded in local `logs/`

## Remaining Work
- finish the bounded default-`~/.codex` smoke check and record the result
- refresh `agent_docs/CHANGELOG.md` for the `0.116.0` line
- commit, push, tag, and publish the `0.116.0` release if the remaining release checks stay green

## Handoff Rule
Do not release or publish from any older base.
