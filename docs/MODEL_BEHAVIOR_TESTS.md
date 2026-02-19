# Model Behavior Smoke Tests

Manual validation is required for both LiteLLM model families before every
pushed release. These tests use the debug Codex binary and the canonical
`~/.codex-litellm-debug` configuration so telemetry stays enabled and the run
matches our published artifacts.

## Test Setup

1. `cargo build --locked --bin codex` inside `codex/codex-rs`.
2. Recreate the Calibre-Web workspace so the repo state is deterministic:  
   `rm -rf test-workspace && ./setup-test-env.sh`
3. `cd test-workspace`
4. Run each scenario with  
   `CODEX_HOME=/root/.codex-litellm-debug ../codex/codex-rs/target/debug/codex exec "<prompt>" --model <slug> --skip-git-repo-check`

## Required Scenarios

| Type | Model | Prompt | Expected Result |
|------|-------|--------|-----------------|
| Non-agentic (no interleaved thinking) – run **first** | `vercel/gpt-oss-120b` (medium reasoning) | `change all buttons in the repository to have a gradient and pill shape. Just do it. Do not ask for permission.` | Model must keep issuing tool calls until the repository is actually edited, then produce a final assistant message. No manual “continue” inputs, disconnects, or stuck “Re-connecting…” loops are allowed. |
| Agentic / interleaved thinking | `vercel/minimax-m2` (medium reasoning) | Same prompt | Model emits reasoning/tool chatter plus final answer. In the TUI/exec transcript, the intermediate “thinking” logs must render italic + gray (Reasoning history cells) instead of plain assistant text. |

If either run fails, capture the rollout log inside
`~/.codex-litellm-debug/sessions/YYYY/MM/DD/` plus terminal output and block the
release until the regression is understood.

> **Note:** Minimax-style runs often exceed the default exec timeout (~6½ min). If the turn times out mid-edit, capture the log, rerun with a higher timeout, and do not ship the release until the agent can finish.

## Current Findings

- **2025‑11‑07:** `vercel/gpt-oss-120b` now keeps running tools until it can apply the gradient/pill styling (see `logs/gpt-oss-20251107-182214.log`). Keep an eye on the fallback summary to ensure it only fires after real edits land.
- `vercel/minimax-m2` streams reasoning correctly but can exceed the default exec timeout; the latest run (`logs/minimax-20251107-181116.log`) hit the 395 s ceiling while still editing CSS, so bump `--exec-timeout` if the agent needs more time.

Document new findings here as tests evolve so release drivers know the exact
behaviour to look for.
