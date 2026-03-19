# Changelog

This file tracks user-visible changes in `codex-litellm`.

## Unreleased
`codex-litellm` now treats the LiteLLM `/responses` API as the default and only forward path for current release work. The `0.115.0` line stays focused on agentic models that can complete Codex-style tool loops on `/responses`. `vercel/deepseek-v3.2-thinking` remains a known blocker on that path: the current LiteLLM/Vercel bridge still rejects tool-use follow-up turns with a missing `reasoning_content` error, so DeepSeek is documented as incompatible on `/responses` until that provider-side behavior changes or we add a deliberate fallback path.

The repo now also carries a public smoke bench and published public-facing results. That bench resolves live gateway model IDs at runtime, sanitizes private route segments before writing committed output, and currently shows:
- pass: `vercel/minimax-m2.7-highspeed`
- pass: `vercel/gemini-3.1-pro-preview`
- fail: `vercel/deepseek-v3.2-thinking`
- fail: `vercel/glm-5-turbo`
- fail: `vercel/kimi-k2.5`
- fail: `vercel/grok-4.20-reasoning-beta`

### Highlights
- Kept the `0.115.0` upstream refresh as the active release line and tightened the patchset around the LiteLLM `/responses` runtime.
- Added explicit runtime metadata for the current green agentic models on `/responses`, so supported models no longer silently fall back to generic defaults.
- Documented the DeepSeek `/responses` blocker as a real provider-bridge issue, not an ambiguous model-quality failure.
- Updated operator docs and release notes so future publishes treat `/responses` as the default path forward.
- Added a public smoke bench and moved the README toward current live results, economics, and reproducible user-facing guidance.
- Refreshed the bench to current live slugs on this gateway: MiniMax M2.7 highspeed, Gemini 3.1 Pro Preview, GLM-5 turbo, Kimi K2.5, DeepSeek V3.2 Thinking, and Grok 4.20 reasoning beta.

### Detailed Changes
- runtime: added explicit model metadata for `vercel/minimax-m2.5`, `vercel/kimi-k2.5`, and `vercel/deepseek-v3.2-thinking` in the maintained `0.115.0` patchset.
- validation: re-ran live `/responses` smokes on the fixture harness and confirmed:
  - `vercel/minimax-m2.5` passes
  - `vercel/kimi-k2.5` passes
  - `vercel/deepseek-v3.2-thinking` still fails during tool-use follow-up turns with missing `reasoning_content`
- docs: updated `agent_docs/CURRENT_TASK.md` and `agent_docs/TODOS.md` with the direct backend probe results, so the remaining DeepSeek failure is tracked as a concrete LiteLLM `/responses` bridge problem.
- docs: kept release guidance opinionated around the supported path: GitHub builds, npm publish from CI, and agentic validation on LiteLLM `/responses`.

## Format
Use VS Code-style release notes:
- short intro paragraph
- `Highlights`
- `Detailed Changes`
