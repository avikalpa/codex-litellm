# Public Smoke Bench

Latest live smoke run against a LiteLLM /responses endpoint using the public fixture bench.

- fixture: `mini-web`
- profile path: `custom LiteLLM profile`
- exact gateway-specific route segments are intentionally not published

| Model family | Public slug | Status | Notes |
| --- | --- | --- | --- |
| minimax | `vercel/minimax-m2.5` | pass | Best current value path for Codex-style editing. |
| glm | `vercel/glm-5-turbo` | pass | Rechecked after gateway fix. |
| claude-haiku | `vercel/claude-haiku-4.5` | pass | Cheap fast route; verify reliability on your own endpoint. |
| deepseek | `vercel/deepseek-v3.2-thinking` | fail | Known /responses bridge risk around reasoning follow-up turns. |
| grok-fast | `vercel/grok-4.1-fast-reasoning` | fail | Economics-oriented Grok fast reasoning route. |

Regenerate with:

```bash
scripts/run-public-smoke-bench.sh --profile ~/.codex
```
