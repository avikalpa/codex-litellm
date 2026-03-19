# codex-litellm

`codex-litellm` is upstream Codex CLI with a maintained LiteLLM patchset.

It keeps the Codex agent loop, but lets you run it against agentic models from multiple providers through one LiteLLM gateway.

- Software license: Apache-2.0
- Documentation license: CC BY 4.0
- Current upstream base: `rust-v0.115.0`
- Default runtime path: LiteLLM `/responses`

## Why This Exists

Official Codex is the right path when you want the official OpenAI-hosted harness.

`codex-litellm` exists for a different use case:
- one Codex CLI talking to many providers through LiteLLM
- agentic coding models that can inspect a repo, use tools, edit files, and stop cleanly
- cheaper model experimentation without giving up the Codex workflow
- a maintained patchset that stays close to upstream instead of becoming a permanent fork

## What Changed Recently

This is the user-facing changelog for the current line.

### `0.115.0` line
- LiteLLM `/responses` is now the default and intended path forward.
- `codex-litellm` uses the normal `~/.codex` home and keeps its remembered model state under a dedicated hidden profile so plain `codex` does not get clobbered.
- The smoke harness is stricter now: a model does not pass unless it makes a real repo edit and then finalizes.
- The public smoke bench is now part of the repo so you can run the same basic checks against your own endpoint.
- DeepSeek remains a known blocker on `/responses` because some tool-use follow-up turns still fail with missing `reasoning_content`.

## What Works Best Today

`codex-litellm` is agentic-first. Non-agentic models are deprecated for primary use.

The practical recommendation today is:
- start with MiniMax or Kimi
- try GLM, Claude Haiku, or Grok fast reasoning only after your own endpoint proves them on the smoke bench
- do not spend premium-model money through a weak bridge path if the official provider path is available

Why this matters:
- the public cares about benchmark screenshots
- the real product question is whether the model can finish Codex-style repo work
- the project optimizes for agent loops, not for making every expensive flagship model a good buy through LiteLLM

## Current Live Smoke Status

These statuses come from the repo's basic smoke bench on a LiteLLM `/responses` gateway.

- green: `vercel/minimax-m2.5`
- green: `vercel/kimi-k2.5`
- green on the current public bench: `vercel/glm-5-turbo`
- green on the current public bench: `vercel/claude-haiku-4.5`
- red: `vercel/deepseek-v3.2-thinking`
- red on the current public bench: `vercel/grok-4.1-fast-reasoning`

Interpretation:
- MiniMax is the best current value path for Codex-style editing.
- Kimi is also a strong verified route.
- DeepSeek is still blocked on the current LiteLLM `/responses` bridge.
- GLM was fixed at the gateway and now passes the current public bench on this endpoint.
- Haiku now passes the current public bench on this endpoint.
- Grok fast is still an economics-oriented route, but on this endpoint it failed the current smoke bench before producing a repo edit.

See the committed public bench output in `benchmarks/public-smoke-results.md`.

## Install

```bash
npm install -g @avikalpa/codex-litellm
```

This installs:

```bash
codex-litellm
```

The npm package downloads a prebuilt binary from GitHub Releases for your platform.

## Quick Start

Use the normal Codex home. `codex-litellm` should only need two extra inputs over plain Codex:
- your LiteLLM `/v1` base URL
- your LiteLLM API key

Put them in `~/.codex/.env`:

```bash
mkdir -p ~/.codex
cat > ~/.codex/.env <<'EOF2'
LITELLM_BASE_URL=http://localhost:4000/v1
LITELLM_API_KEY=your-litellm-api-key
EOF2
```

Then point the built-in `litellm` provider at `/responses` in `~/.codex/config.toml`:

```toml
[model_providers.litellm]
name = "LiteLLM"
base_url = "http://localhost:4000/v1"
env_key = "LITELLM_API_KEY"
wire_api = "responses"

[profiles.codex-litellm]
model = "vercel/minimax-m2.5"
```

Start the CLI:

```bash
codex-litellm
```

Or run one-shot commands:

```bash
codex-litellm exec "Summarize this repository"
codex-litellm exec "Refactor this function" --model vercel/minimax-m2.5
```

## Model Selection

If you want the best chance of a clean first experience:
- `vercel/minimax-m2.5`
- `vercel/kimi-k2.5`

If you want cheaper experimentation after the basics work:
- `vercel/claude-haiku-4.5`
- `vercel/glm-5-turbo`
- `vercel/grok-4.1-fast-reasoning`

If you want a warning before wasting money:
- do not assume expensive frontier models are automatically the best value through LiteLLM
- if you are about to run a premium model through a bridge layer only to get generic tool behavior, you are often better off with the official provider harness
- `codex-litellm` shines when paired with strong, efficient, agentic models

## Run The Same Smoke Bench We Use

The repository now includes a public smoke bench so anyone can test their own LiteLLM endpoint.

What it does:
- resolves live model IDs from your gateway inventory
- runs a basic Codex-style edit task on a small fixture repo
- requires a real repo diff before calling the run a pass
- publishes sanitized results without exposing private route segments

Run it:

```bash
scripts/run-public-smoke-bench.sh --profile ~/.codex
```

Current focus models in that bench:
- MiniMax
- GLM
- Claude Haiku
- DeepSeek
- Grok fast reasoning

Public result files:
- `benchmarks/public-smoke-results.md`
- `benchmarks/public-smoke-results.json`

The exact route chosen for each family is discovered from your LiteLLM `/v1/models` inventory at runtime.

## Good First Commands

UI change:

```bash
codex-litellm exec "Change all primary buttons to pill-shaped gradient buttons" --model vercel/minimax-m2.5
```

Code review:

```bash
codex-litellm exec "Review the last set of changes for bugs and regressions" --model vercel/kimi-k2.5
```

Bugfix plus test:

```bash
codex-litellm exec "Find why this test is failing, fix it, and update the test if needed" --model vercel/minimax-m2.5
```

CLI change:

```bash
codex-litellm exec "Add a --verbose flag, update README usage, and add a test" --model vercel/grok-4.1-fast-reasoning
```

Interactive session:

```bash
codex-litellm --model vercel/minimax-m2.5
```

## Semantic Cache

If your LiteLLM deployment supports semantic cache, use it.

The cheap way to do this is to back the cache lookup with a low-cost embedding model. That keeps cache lookup cost close to zero relative to a full reasoning-model turn.

A good example shape is:
- `vercel/gemini-embedding-001`

The cache backend belongs in your LiteLLM deployment, not in `codex-litellm`, but the user outcome is simple:
- lower repeat-call cost
- better economics for iterative Codex loops
- almost-zero marginal cost for cache probes when the embedding route is cheap

## Common Pitfalls

- Do not start with non-agentic models.
- Do not assume `/v1/models` means a route is release-ready for Codex-style tasks.
- Do not assume DeepSeek is safe on `/responses` yet.
- Do not build your workflow around a custom debug `CODEX_HOME`; the intended path is normal `~/.codex`.
- Do not keep burning tokens on premium models through a weak bridge path if the official harness would be better.

## Troubleshooting

If a model behaves badly:

1. Check that your LiteLLM gateway is reachable.
2. Check that the slug exists on `/v1/models`.
3. Run `scripts/run-public-smoke-bench.sh --profile ~/.codex`.
4. Retry with MiniMax or Kimi before blaming the Codex patchset.

If install fails:

1. Verify GitHub Releases is reachable.
2. Re-run `npm install -g @avikalpa/codex-litellm`.
3. If your platform is unsupported, build from source.

## Project Direction

The goal is not to outgrow Codex.

The goal is to keep upstream Codex usable over LiteLLM while staying honest about:
- provider quirks
- model quirks
- telemetry and reproducibility
- benchmark claims versus actual repo-edit performance
- portability of the patchset to the next upstream stable tag

## For Developers

User-facing docs stop here. Operator docs live in:
- `AGENTS.md`
- `agent_docs/PUBLISHING.md`
- `agent_docs/CURRENT_TASK.md`
- `agent_docs/MODEL_BEHAVIOR_TESTS.md`
- `agent_docs/CHANGELOG.md`

## Licensing

- Software, patches, build scripts, package metadata, and shipped artifacts: `Apache-2.0`
- Documentation and prose in `README.md`, `AGENTS.md`, and `agent_docs/`: `CC BY 4.0`
