# Changelog

This file tracks user-visible changes in `codex-litellm`.

## Unreleased
`codex-litellm` is now refreshed onto upstream `rust-v0.116.0` and keeps LiteLLM `/responses` as the default forward path. The release line remains intentionally agentic-first: the current recommended default is MiniMax, and DeepSeek remains a documented blocker on the LiteLLM `/responses` bridge for tool-follow-up turns.

Current public-facing model picture on this gateway:
- pass: `vercel/minimax-m2.7-highspeed`
- pass: `vercel/claude-haiku-4.5`
- amber: `vercel/glm-5-turbo`
- watchlist: `vercel/gemini-3.1-pro-preview`
- watchlist: `vercel/grok-4.20-reasoning-beta`
- research-only split result: `vercel/kimi-k2.5`
- blocked: `vercel/deepseek-v3.2-thinking`

### Highlights
- Refreshed the maintained patchset onto upstream `rust-v0.116.0`.
- Kept LiteLLM `/responses` as the supported path and updated release metadata to the new base.
- Hardened stream handling so out-of-order text/reasoning deltas no longer panic debug sessions.
- Revalidated the current MiniMax route as the best default live editing path on this gateway.
- Updated the README to steer users toward the current agentic routes, away from weak or expensive paths, and toward LiteLLM semantic cache with cheap embeddings.
- Tightened the active smoke bench around MiniMax, GLM, Kimi, and Claude Haiku, with DeepSeek tracked separately as a blocked route.
- Made the UI smoke prompt explicit enough to force a measurable restyle instead of inviting “already done” false passes.
- Restored Gemini 3.1 Pro Preview and Grok 4.20 to the research/watchlist lane instead of dropping them from testing entirely.
- Added stricter `python-cli` fixture validation so a model must change the CLI file, README, and tests to count as a pass.
- Turned the README into a live research report with fixture methodology, model-by-model tables, and harness implications.

### Detailed Changes
- upstream: rebased the maintained LiteLLM patchset onto `rust-v0.116.0` and regenerated `stable-tag.patch` from that exact tag.
- runtime: preserved LiteLLM tool normalization, retry-state reset, transient follow-up instructions, and post-edit shell guards on the new upstream base.
- runtime: downgraded out-of-order streamed delta handling from debug panic to warning so Codex sessions survive provider event-order quirks.
- validation: confirmed `vercel/minimax-m2.7-highspeed` passes the current `mini-web` smoke on the `0.116.0` tree.
- validation: re-ran current bench candidates and confirmed:
  - `vercel/kimi-k2.5` still fails the explicit UI fixture, but now passes the stricter procedural `python-cli` task
  - `vercel/deepseek-v3.2-thinking` is still blocked by the current LiteLLM `/responses` follow-up path
  - `vercel/glm-5-turbo` remains noisy enough under retry/rate-limit pressure to fail the focused reruns on both the procedural fixture and the initial heavy-repo probe
  - `vercel/claude-haiku-4.5` now clears both the explicit `mini-web` prompt and the stricter `python-cli` task
- validation: restored Gemini 3.1 Pro Preview and Grok 4.20 to the research/watchlist bench:
  - `vercel/gemini-3.1-pro-preview` makes the right edit on the explicit fixture prompt, but still stalls or times out too often after the diff to count as clean green
  - `vercel/grok-4.20-reasoning-beta` clears the explicit fixture prompt, but fails the current strict `python-cli` rerun under rate-limit pressure
- validation: MiniMax now also clears the stricter `python-cli` task, strengthening its default recommendation.
- validation: the first `calibre-web` heavy-repo probes show a different boundary than the lightweight fixtures:
  - `vercel/minimax-m2.7-highspeed` still looks like the best default route, but the latest heavy probe failed under route pressure before a clean diff
  - the larger repo amplifies retry and rate-limit behavior enough that future harness work should focus on backoff and clean post-edit finalization, not only model ranking
- validation: kept DeepSeek out of the default public bench so the active green/amber/red matrix is not diluted by a known blocked route.
- docs: rewrote `README.md` around real user experience, current model guidance, live research findings, `/responses`, economic tradeoffs, and LiteLLM semantic cache guidance.

## Format
Use VS Code-style release notes:
- short intro paragraph
- `Highlights`
- `Detailed Changes`
