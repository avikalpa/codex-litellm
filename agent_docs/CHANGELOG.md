# Changelog

This file tracks user-visible changes in `codex-litellm`.

## Unreleased
`codex-litellm` is now refreshed onto upstream `rust-v0.116.0` and keeps LiteLLM `/responses` as the default forward path. The release line remains intentionally agentic-first: the current recommended default is MiniMax, and DeepSeek remains a documented blocker on the LiteLLM `/responses` bridge for tool-follow-up turns.

Current public-facing model picture on this gateway:
- pass: `vercel/minimax-m2.7-highspeed`
- amber: `vercel/glm-5-turbo`
- fail: `vercel/kimi-k2.5`
- fail: `vercel/claude-haiku-4.5`
- fail: `vercel/deepseek-v3.2-thinking`

### Highlights
- Refreshed the maintained patchset onto upstream `rust-v0.116.0`.
- Kept LiteLLM `/responses` as the supported path and updated release metadata to the new base.
- Hardened stream handling so out-of-order text/reasoning deltas no longer panic debug sessions.
- Revalidated the current MiniMax route as the best default live editing path on this gateway.
- Updated the README to steer users toward the current agentic routes, away from weak or expensive paths, and toward LiteLLM semantic cache with cheap embeddings.

### Detailed Changes
- upstream: rebased the maintained LiteLLM patchset onto `rust-v0.116.0` and regenerated `stable-tag.patch` from that exact tag.
- runtime: preserved LiteLLM tool normalization, retry-state reset, transient follow-up instructions, and post-edit shell guards on the new upstream base.
- runtime: downgraded out-of-order streamed delta handling from debug panic to warning so Codex sessions survive provider event-order quirks.
- validation: confirmed `vercel/minimax-m2.7-highspeed` passes the current `mini-web` smoke on the `0.116.0` tree.
- validation: re-ran current bench candidates and confirmed:
  - `vercel/kimi-k2.5` still finalizes without a repo diff
  - `vercel/deepseek-v3.2-thinking` is still blocked by the current LiteLLM `/responses` follow-up path
  - `vercel/glm-5-turbo` can edit, but the current route is still noisy under retry/rate-limit pressure
  - `vercel/claude-haiku-4.5` is not yet a clean pass on this fixture
- docs: rewrote `README.md` around real user experience, current model guidance, `/responses`, economic tradeoffs, and LiteLLM semantic cache guidance.

## Format
Use VS Code-style release notes:
- short intro paragraph
- `Highlights`
- `Detailed Changes`
