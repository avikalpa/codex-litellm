# Current Task — 0.132.0 Upstream Refresh

Last updated: 2026-05-20

## TL;DR
- Upstream stable target: `rust-v0.132.0`.
- `codex/` is checked out at upstream commit `13595c36e218fcbd13df118eeadf00d4eb0e6d31`.
- `/responses` is the default and supported LiteLLM path.
- `/chat/completions` is deprecated; do not add new chat-completions config or validation paths.
- Operator docs now live in `docs/`.

## Patch Direction
- Keep the patchset close to upstream.
- Preserve LiteLLM provider setup, `/models` discovery, tool-schema compatibility, and reasoning-parameter fallback.
- Remove project-specific context-management policy and rely on upstream Codex defaults.
- Keep UI changes limited to first-run LiteLLM setup and the LiteLLM `/model` selector.

## Validation State
- `cargo build --locked --bin codex`: pass.
- `cargo build --locked --bin codex-litellm`: pass.
- `cargo test --locked -p codex-api parses_openai_compatible_models_response`: pass.
- `cargo test --locked -p codex-core codex_litellm`: pass.
- `cargo test --locked -p codex-model-provider-info merge_configured_model_providers`: pass.
- `cargo test --locked -p codex-models-manager namespaced`: pass.
- `cargo test --locked -p codex-exec resume_lookup_model_providers_filters_only_last_lookup`: pass.
- TUI focused resume/model tests: pass.
- `./scripts/test-build-sh-metadata.sh`: pass.
- `./scripts/test-npm-release-version.sh`: pass.
- `./scripts/test-default-codex-home.sh`: pass.
- `./scripts/test-shared-session-resume.sh`: pass.
- `stable-tag.patch` apply check against a fresh `rust-v0.132.0` worktree: pass.
- Live model gate: pass with `vercel/maa/minimax-m2.7-highspeed`.
  - Stale route `vercel/minimax-m2.7-highspeed` failed with `/responses` invalid model.
  - Passing rollout: `/home/pi/.codex-litellm-debug/sessions/2026/05/21/rollout-2026-05-21T00-48-18-019e46d3-11db-73d3-adb2-e288f5e3a088.jsonl`.
  - Evidence: non-empty fixture diff in `test-workspace/cps/static/css/style.css` and final assistant reply.

## Required Before Release
- Commit and push the CI packaging fix.
- Delete the failed `v0.132.0+13595c36+litfcc2f5f` release/tag or supersede it with the fixed release tag.
- Create the replacement GitHub release and verify npm `latest`.

## Handoff Rule
Do not release or publish from any older base.
