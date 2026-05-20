# Supported Models

## Policy
- `codex-litellm` is agentic-first.
- Supported models should be able to inspect a repo, use tools, edit files, and finalize reliably in Codex-style tasks.
- Non-agentic models are deprecated for primary use. They remain compatibility paths, not the design center.
- The allowlist is a policy filter, not a claim that every listed model works perfectly under every provider.

## Current Agentic Candidate Families
These are documentation candidates and release-research targets, not a hard-coded picker allowlist. The LiteLLM `/model` selector should prefer gateway discovery from `/v1/models`.

- `gpt-5.4`
- `gpt-5.4-pro`
- `gpt-5.3-codex`
- `claude-sonnet-4.6`
- `claude-opus-4.6`
- `claude-haiku-4.5`
- `gemini-3.1-pro-preview`
- `gemini-3-pro`
- `gemini-3-flash`
- `glm-5`
- `glm-5.1`
- `grok-4.1-fast-reasoning`
- `deepseek-v4-pro`
- `minimax-m2.7-highspeed`
- `kimi-k2.6`

## Required Release-Gate Models
These are not the whole allowlist. They are the current mandatory live checks before release.
- agentic release gate: current gateway-discovered MiniMax release route
- currently: `vercel/maa/minimax-m2.7-highspeed`

## Deprecated Compatibility Models
- `vercel/gpt-oss-120b`
- Deprecated non-agentic models are not release gates. Use them only for explicit compatibility/debugging work.

## Evidence Sources
- Artificial Analysis model inventory
- Artificial Analysis agentic benchmark pages
- LiteLLM gateway `/v1/models` inventory
- real `codex-litellm` smoke tests

## Current `/responses` Reality
- Green:
  - `vercel/maa/minimax-m2.7-highspeed`
  - `vercel/maa/claude-haiku-4.5`
- Amber:
  - `vercel/maa/glm-5.1` needs a fresh matrix run on the refreshed route before promotion
- Watchlist:
  - `vercel/gemini-3.1-pro-preview` because it makes the right edit on the explicit fixture prompt, but still stalls too long after the diff
  - `vercel/grok-4.20-reasoning-beta` because it clears the explicit fixture prompt, but fails the stricter `python-cli` rerun under rate-limit pressure
- Split / research-only:
  - `vercel/maa/kimi-k2.6` needs a fresh matrix run on the refreshed route
  - `vercel/maa/deepseek-v4-pro` is newly visible on the gateway; previous DeepSeek routes had `/responses` follow-up issues, so keep it research-only until it passes a live gate

## Refresh Rules
- Refresh evidence before changing the allowlist.
- Prefer gateway-canonical slugs when they differ from benchmark naming.
- Remove or downgrade models that stop behaving agentically in real runs.
