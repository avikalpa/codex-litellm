# Supported Models

## Policy
- `codex-litellm` is agentic-first.
- Supported models should be able to inspect a repo, use tools, edit files, and finalize reliably in Codex-style tasks.
- Non-agentic models are deprecated for primary use. They remain compatibility paths, not the design center.
- The allowlist is a policy filter, not a claim that every listed model works perfectly under every provider.

## Current Agentic Allowlist
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
- `glm-5-turbo`
- `grok-4.1-fast-reasoning`
- `deepseek-v3.2-thinking`
- `minimax-m2.5`
- `kimi-k2.5`

## Required Release-Gate Models
These are not the whole allowlist. They are the current mandatory live checks before release.
- agentic release gate: `vercel/minimax-m2.5`

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
  - `vercel/minimax-m2.5`
  - `vercel/kimi-k2.5`
- Red:
  - `vercel/deepseek-v3.2-thinking` because the current LiteLLM `/responses` bridge still rejects some tool-use follow-up turns with missing `reasoning_content`
  - `vercel/claude-haiku-4.5` because it still fails to produce reliable repo edits in our current smoke harness
  - `vercel/glm-5-turbo` because the current gateway route resolves to a missing backend model and then retries into rate limits

## Refresh Rules
- Refresh evidence before changing the allowlist.
- Prefer gateway-canonical slugs when they differ from benchmark naming.
- Remove or downgrade models that stop behaving agentically in real runs.
