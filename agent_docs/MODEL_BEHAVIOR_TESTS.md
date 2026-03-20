# Model Behavior Tests

These are the required live smoke tests before push or release.

## Environment
- Build from `codex/codex-rs`:
  - `cargo build --locked --bin codex`
- Recreate the test repo for clean runs:
  - `rm -rf test-workspace && ./setup-test-env.sh`
- For fixture-driven research runs beyond `calibre-web`:
  - `./scripts/setup-test-repo.sh --refresh <fixture> test-workspace`
- Run from `test-workspace` with the canonical LiteLLM profile:
  - `CODEX_HOME=/home/pi/.codex-litellm-debug ../codex/codex-rs/target/debug/codex exec "<prompt>" --model <slug> --skip-git-repo-check`

## Required Order
1. Agentic release gate

## Required Models
- Agentic release gate:
  - current gateway-discovered MiniMax release route
  - currently: `vercel/minimax-m2.7-highspeed`

## Canonical Prompt
`change every button and button-like input in the repository to use a diagonal gradient from #195c53 to #d17a2d, a 999px pill radius, 14px 24px padding, and a stronger hover shadow. Make the repo edit directly and finish after the edit. Do not ask for permission.`

## Pass Criteria
### Agentic release gate
- The model uses tools and/or reasoning normally.
- The model makes a real repo edit.
- After the edit, it terminates with a final assistant reply.
- Reasoning should render as reasoning, not as plain assistant chatter.
- Endless post-edit read-only exploration is a failure.
- A smoke run that returns a final answer without a non-empty `git diff` is a hard failure.

## Failure Handling
- Save the rollout/session logs.
- Record the exact log paths in `agent_docs/CURRENT_TASK.md`.
- Do not release until the failure is explained.

## Notes
- These model slugs are current working release gates, not permanent truths.
- Refresh them when the gateway inventory or supported-model policy changes.
- Use `./scripts/discover-agentic-models.sh --profile /home/pi/.codex-litellm-debug minimax kimi deepseek glm claude-haiku` before hard-coding a release gate slug after gateway changes.
- Deprecated non-agentic models are not release gates anymore. Test them only when explicitly investigating compatibility regressions.

## Research Matrix
- Do not rely only on `calibre-web`.
- Keep at least one lightweight local fixture for each broad repo shape:
  - `mini-web` for HTML/CSS/UI edits
  - `python-cli` for CLI + README + test updates
  - `calibre-web` as the heavier real-world UI repo
- For current agentic model research, the baseline matrix is:
  - `vercel/minimax-m2.7-highspeed`
  - `vercel/kimi-k2.5`
  - `vercel/claude-haiku-4.5`
  - `vercel/glm-5-turbo`
- DeepSeek is tracked separately as a blocked `/responses` route, not part of the default green/amber/red research matrix.
- Runner helpers:
  - `./scripts/run-agentic-model-smoke.sh --fixture <fixture> --model <slug> --profile /home/pi/.codex-litellm-debug`
  - `./scripts/run-agentic-matrix.sh <fixture> /home/pi/.codex-litellm-debug`
  - `./scripts/run-public-smoke-bench.sh --profile ~/.codex`
