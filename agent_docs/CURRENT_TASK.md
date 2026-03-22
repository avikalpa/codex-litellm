# Current Task — 0.116.0 Confidence Work

Last updated: 2026-03-22

## TL;DR
- `codex/` is aligned to upstream `rust-v0.116.0` at commit `38771c90`.
- Root metadata is aligned to the same base:
  - `package.json.version = 0.116.0`
  - `package.json.codexLitellm.baseVersion = 0.116.0`
  - `package.json.codexLitellm.upstreamCommit = 38771c90`
- `stable-tag.patch` has been regenerated from `rust-v0.116.0`.
- `/responses` remains the default LiteLLM path forward.
- DeepSeek remains a known blocked `/responses` route.
- Paid live model sweeps are deferred until the low-cost confidence gates are clean.

## What Landed Recently
- `codex` and `codex-litellm` now intentionally share the same `~/.codex/sessions` store.
- Resuming a session from the other CLI keeps the active executable's provider and default model profile instead of importing the old provider into the new runtime.
- Cross-provider alias warnings are suppressed for obvious pairs such as plain `gpt-5.4` versus a namespaced LiteLLM route for the same model family.
- Release preflight already covered default `~/.codex` bootstrap for LiteLLM config loading.

## Current Validation State
- required debug build: pass
- default `~/.codex` bootstrap smoke: pass locally via `./scripts/test-default-codex-home.sh`
- shared `~/.codex` cross-provider resume smoke: should now be treated as a required low-cost gate
- latest paid live model evidence is unchanged from the previous research pass and should not be refreshed until explicitly requested

## Release Read
- `/responses` is the supported path. Keep new work and release validation centered there.
- DeepSeek is still blocked on the current LiteLLM `/responses` bridge. Do not treat it as a green candidate until the bridge bug is fixed.
- Shared sessions are now product behavior, not a debug convenience. Do not reintroduce provider-specific session silos.
- Default `~/.codex` behavior matters more than debug-only `CODEX_HOME` setups for release confidence.

## Remaining Work
- keep the low-cost release gates green:
  - `./scripts/test-default-codex-home.sh`
  - `./scripts/test-shared-session-resume.sh`
- defer paid live model sweeps until requested
- when paid testing resumes, refresh the active agentic bench from gateway-discovered IDs and keep DeepSeek tracked separately as blocked

## Handoff Rule
Do not release or publish from any older base.
