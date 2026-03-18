# Current Task — 0.104.0 Release Candidate

Last updated: 2026-03-18

## TL;DR
- `codex/` is aligned to upstream `rust-v0.104.0` at commit `74d1f7b2`.
- The LiteLLM follow-up loop in `codex-rs/core/src/codex.rs` remains patched so agentic models can recover from tool-only and summary-only turns instead of stalling.
- Non-agentic models are now deprecated in-product: when a user explicitly selects one, startup shows a warning, and picker descriptions are annotated if we ever fall back to the broader upstream model list.
- `stable-tag.patch` must be regenerated from `git -C codex diff rust-v0.104.0` before every release commit so the root repo stays reproducible.

## Validation
- Final release validation for this sweep is:
  - `cargo test -p codex-core preset_annotation_is_idempotent --lib`
  - `cargo build --locked --bin codex`
- Existing agentic evidence for the button-edit prompt is preserved in `logs/minimax-final.log`.
- Older mandatory-model probes under `logs/model-test-vercel_bon_minimax-m2.log` and `logs/model-test-vercel_bon_gpt-oss-120b.log` still show LiteLLM gateway instability (`502` / high-demand errors). Treat those as backend evidence, not compile regressions in this checkout.

## Release Notes For This Milestone
- Hardened LiteLLM turn recovery for agentic models in `codex-rs/core/src/codex.rs`.
- Added explicit non-agentic model deprecation handling in:
  - `codex-rs/core/src/models_manager/supported_models.rs`
  - `codex-rs/core/src/models_manager/manager.rs`
  - `codex-rs/core/src/codex.rs`
- Root package metadata remains `0.104.0` with npm prerelease identifiers derived during publish.

## Handoff
- After regenerating `stable-tag.patch`, commit the root repo, push `main`, cut the GitHub release tag, and verify the `publish-npm` workflow plus `npm view @avikalpa/codex-litellm version`.
