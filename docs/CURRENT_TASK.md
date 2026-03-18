# Current Task — 0.115.0 Upstream Refresh

Last updated: 2026-03-18

## TL;DR
- `codex/` is aligned to upstream `rust-v0.115.0` at commit `f028679a`.
- Root metadata is already aligned to the same base:
  - `package.json.version = 0.115.0`
  - `package.json.codexLitellm.baseVersion = 0.115.0`
  - `package.json.codexLitellm.upstreamCommit = f028679a`
- `cargo build --locked --bin codex` currently passes on this tree.

## What Already Landed In The 0.115.0 Port
- retry-away handling for LiteLLM `400 UnsupportedParamsError` tied to unsupported reasoning-effort fields
- model-suffix matching fixes for namespaced/custom slugs
- tool normalization so LiteLLM/Vercel accepts function-call tool payloads where upstream request shapes were rejected
- transient follow-up instructions instead of polluting persisted conversation history
- stronger post-edit finalize nudges
- a shell guard that blocks further read-only inspection once the repo already has a diff, except for `git diff --stat`

## Current Release Blocker
- The old LiteLLM/Vercel `"Multiple system messages..."` failure is gone.
- `vercel/bon-gour/minimax-m2.5` now makes real repo edits.
- The release blocker is finalization: after editing successfully, the model can still continue with extra read-only shell exploration instead of sending the final assistant reply.

## Evidence
- `logs/model-test-vercel_bon-gour_minimax-m2.5-0.115.0-postfix2.log`
- `logs/model-test-vercel_bon-gour_minimax-m2.5-0.115.0-postfix3.log`
- `logs/model-test-vercel_bon-gour_minimax-m2.5-0.115.0-postfix4.log`
- Earlier non-agentic schema failure before tool normalization:
  - `logs/model-test-vercel_bon-gour_gpt-oss-120b-0.115.0-postfix.log`

## Verified So Far
- `cargo test -p codex-core get_model_info_matches_multi_segment_namespace_suffix -- --nocapture`
- `cargo test -p codex-core get_model_info_prefers_longest_namespaced_suffix_match -- --nocapture`
- `cargo test -p codex-core should_retry_without_reasoning_only_for_litellm_400s -- --nocapture`
- `cargo test -p codex-core build_responses_request_normalizes_litellm_tools_to_function_only -- --nocapture`
- `cargo test -p codex-core build_tool_call_maps_function_tool_search_to_tool_search_payload -- --nocapture`
- `cargo build --locked --bin codex`

## Next Step
- Make `vercel/bon-gour/minimax-m2.5` terminate cleanly after successful edits.
- Re-run `vercel/bon-gour/gpt-oss-120b` after that.
- Then regenerate `stable-tag.patch`, update release notes if needed, commit, push, tag, and publish from the `0.115.0` base.

## Handoff Rule
Do not release or publish from any older base.
