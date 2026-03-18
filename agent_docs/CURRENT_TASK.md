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
- the same post-edit guard behavior now applies to the live `exec_command` / unified-exec path
- explicit runtime metadata for `vercel/minimax-m2.5` so it no longer silently falls back

## Current Status
- The old LiteLLM/Vercel `"Multiple system messages..."` failure is gone.
- The later LiteLLM duplicate-`tool_call` replay failure is also mitigated enough for the current live gate to finish.
- `vercel/minimax-m2.5` now passes the canonical live gate on `0.115.0`:
  - it makes a real repo edit
  - it performs the single allowed verification step, `git diff --stat`
  - it returns a final assistant reply
- Remaining work is no longer a release blocker. It is quality follow-up:
  - keep reducing low-value exploration on weaker agentic models
  - keep model metadata aligned with real provider behavior
  - keep telemetry ahead of the next regression

## Research Follow-Up
- The new fixture-based harness now covers more than `calibre-web`:
  - `mini-web` for lightweight HTML/CSS/UI edits
  - `python-cli` for CLI + README + test updates
- Current live results on `mini-web`:
  - `vercel/minimax-m2.5`: pass
  - `vercel/kimi-k2.5`: pass
  - `vercel/deepseek-v3.2-thinking`: fails at the gateway with missing `reasoning_content` during tool-use turns
- Current live result on `python-cli`:
  - `vercel/minimax-m2.5`: pass on a non-UI repo shape
- Direct backend probes against `https://litellm.example.com/v1/responses` narrowed the DeepSeek failure:
  - replaying `reasoning + message + function_call + function_call_output` in the current Codex `/responses` shape still fails
  - replaying the exact prior `/responses` output items plus `function_call_output` still fails
  - using `previous_response_id` with only `function_call_output` still fails, with both `store=false` and `store=true`
  - conclusion: the remaining DeepSeek breakage is the LiteLLM/Vercel `/responses` bridge for thinking+tools, not missing runtime metadata

## Evidence
- `logs/model-test-vercel_minimax-m2.5-0.115.0-postfix2.log`
- `logs/model-test-vercel_minimax-m2.5-0.115.0-postfix3.log`
- `logs/model-test-vercel_minimax-m2.5-0.115.0-postfix4.log`
- duplicate-`tool_call` failure before the retry-state reset:
  - `logs/model-test-vercel_minimax-m2.5-0.115.0-postfix5.log`
  - `logs/model-test-vercel_minimax-m2.5-0.115.0-postfix7.log`
  - `logs/model-test-vercel_minimax-m2.5-0.115.0-postfix8.log`
- current passing run with residual over-exploration / duplicated CSS block:
  - `logs/model-test-vercel_minimax-m2.5-0.115.0-postfix9.log`
- current passing run after explicit `minimax` metadata and stricter shell-write detection:
  - `logs/model-test-vercel_minimax-m2.5-0.115.0-postfix10.log`
- current passing run after porting the post-edit guard onto the live `exec_command` path:
  - `logs/model-test-vercel_minimax-m2.5-0.115.0-postfix11.log`
- new fixture-based research runs:
  - `logs/model-test-vercel_deepseek-v3.2-thinking-mini-web-20260318-192213.log`
  - `logs/model-test-vercel_minimax-m2.5-mini-web-20260318-192400.log`
  - `logs/model-test-vercel_kimi-k2.5-mini-web-20260318-192519.log`
  - `logs/model-test-vercel_minimax-m2.5-python-cli-20260318-192647.log`
- Earlier non-agentic schema failure before tool normalization:
  - `logs/model-test-vercel_gpt-oss-120b-0.115.0-postfix.log`

## Verified So Far
- `cargo test -p codex-core get_model_info_matches_multi_segment_namespace_suffix -- --nocapture`
- `cargo test -p codex-core get_model_info_prefers_longest_namespaced_suffix_match -- --nocapture`
- `cargo test -p codex-core should_retry_without_reasoning_only_for_litellm_400s -- --nocapture`
- `cargo test -p codex-core build_responses_request_normalizes_litellm_tools_to_function_only -- --nocapture`
- `cargo test -p codex-core build_tool_call_maps_function_tool_search_to_tool_search_payload -- --nocapture`
- `cargo test -p codex-core prefer_http_after_retryable_stream_error_only_for_litellm_websockets -- --nocapture`
- `cargo test -p codex-core reset_state_after_retryable_stream_error_ -- --nocapture`
- `cargo test -p codex-core normalize_removes_duplicate_function_calls_with_same_call_id -- --nocapture`
- `cargo test -p codex-core output_redirection_counts_as_mutating_shell_command -- --nocapture`
- `cargo test -p codex-core blocks_read_only_exec_commands_after_successful_mutating_exec_command -- --nocapture`
- `cargo test -p codex-core exec_output_redirection_counts_as_mutating_shell_command -- --nocapture`
- `cargo test -p codex-core known_minimax_model_uses_tuned_metadata_instead_of_fallback -- --nocapture`
- `cargo build --locked --bin codex`

## Next Step
- Keep runtime metadata for `vercel/kimi-k2.5` and `vercel/deepseek-v3.2-thinking` in-tree so they do not silently fall back.
- Decide whether to:
  - port the old LiteLLM chat-completions fallback for DeepSeek thinking+tools, or
  - keep DeepSeek marked as known-broken on the LiteLLM `/responses` path until upstream fixes the bridge.
- Keep using the fixture harness, not only `calibre-web`, for agentic model research.
- Deprecated non-agentic models are not release gates anymore; only re-run them when explicitly debugging compatibility.

## Handoff Rule
Do not release or publish from any older base.
