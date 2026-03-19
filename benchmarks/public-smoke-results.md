# Public Smoke Bench

Latest live smoke run against a LiteLLM /responses endpoint using the public fixture bench.

- fixture: `mini-web`
- profile path: `custom LiteLLM profile`
- exact gateway-specific route segments are intentionally not published

| Model family | Public slug | Status | Notes |
| --- | --- | --- | --- |
| minimax | `vercel/minimax-m2.7-highspeed` | pass | Best current value path for Codex-style editing. Passed after a stream retry. |
| glm | `vercel/glm-5-turbo` | fail | Strong model family, but this run timed out before a valid completion. |
| kimi | `vercel/kimi-k2.5` | fail | Strong AA model, but this run falsely declared success without a repo diff. |
| deepseek | `vercel/deepseek-v3.2-thinking` | fail | Current /responses bridge still fails with missing reasoning_content. |
| gemini-pro | `vercel/gemini-3.1-pro-preview` | pass | Passed, but leaked internal planning chatter; not a clean default. |
| grok-fast | `vercel/grok-4.20-reasoning-beta` | fail | Rate-limited on this endpoint before producing a repo edit. |

Regenerate with:

```bash
scripts/run-public-smoke-bench.sh --profile ~/.codex
```
