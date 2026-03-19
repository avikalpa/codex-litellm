# codex-litellm

`codex-litellm` is upstream Codex CLI with a maintained LiteLLM patchset.

It keeps the Codex agent loop, but lets you run it against agentic models from multiple providers through one LiteLLM gateway.

- Software license: Apache-2.0
- Documentation license: CC BY 4.0
- Current upstream base: `rust-v0.115.0`
- Default runtime path: LiteLLM `/responses`

## Executive Summary

This project exists for one question:

Can Codex-style repo editing work well over LiteLLM with real non-OpenAI models?

Current answer:
- yes, but model choice matters a lot
- benchmark strength is not enough
- live repo-edit behavior matters more than leaderboard placement

On the current public smoke bench, the best default is:
- `vercel/minimax-m2.7-highspeed`

The most interesting but still risky route is:
- `vercel/gemini-3.1-pro-preview`

Models currently failing the bench on this endpoint are:
- `vercel/glm-5-turbo`
- `vercel/kimi-k2.5`
- `vercel/deepseek-v3.2-thinking`
- `vercel/grok-4.20-reasoning-beta`

## Why This Exists

Official Codex is the right path when you want the official hosted harness.

`codex-litellm` is for a different use case:
- one Codex CLI talking to many providers through LiteLLM
- agentic coding models that can inspect a repo, use tools, edit files, and stop cleanly
- cheaper model experimentation without giving up the Codex workflow
- a maintained patchset that stays close to upstream instead of becoming a permanent fork

## Research Question

For a public audience, the real question is not:
- which model is smartest in a benchmark chart?

The real question is:
- which model actually completes a Codex-style edit loop in a real repo?

That means a model must:
- inspect the repo
- use tools without breaking
- make a real file edit
- stop after the edit
- return a usable final answer

Anything less is not a real pass.

## Method

We keep a public smoke bench in this repository.

It does four things:
1. resolves live model IDs from your LiteLLM `/v1/models` inventory
2. runs a real Codex-style edit task on a small fixture repo
3. requires a non-empty repo diff before calling a run a pass
4. publishes sanitized output without exposing private gateway route segments

The current fixture is intentionally simple:
- task: change all buttons to have a gradient and pill shape
- repo shape: small HTML/CSS/JS project
- outcome required: real edit plus final answer

Public bench files:
- `benchmarks/public-smoke-results.md`
- `benchmarks/public-smoke-results.json`

## Current Findings

### Green
- `vercel/minimax-m2.7-highspeed`

Why it is green:
- it made a real repo edit
- it recovered from a stream retry and still finalized
- it is the best current value/default route on this endpoint

### Amber
- `vercel/gemini-3.1-pro-preview`

Why it is not a clean default:
- it passed the smoke
- but it leaked internal planning chatter into the assistant stream
- that makes it interesting, not trustworthy enough to be the first recommendation

### Red
- `vercel/glm-5-turbo`
  - timed out before valid completion
- `vercel/kimi-k2.5`
  - confidently claimed success without producing a repo diff
- `vercel/deepseek-v3.2-thinking`
  - still fails on the LiteLLM `/responses` bridge with missing `reasoning_content`
- `vercel/grok-4.20-reasoning-beta`
  - rate-limited before producing a repo edit

## Public Takeaway

If you only want one answer right now:
- start with MiniMax

If you want one more model to test because benchmarks are too compelling to ignore:
- test Gemini 3.1 Pro Preview, but do not trust it blindly

If you care about price/performance:
- MiniMax is the current practical winner here
- Grok is still interesting economically, but it is not working cleanly enough yet

If you care about raw benchmark prestige:
- use that as a shortlist, not as proof
- Codex-style editing is stricter than chat or reasoning benchmarks

## Artificial Analysis Cross-Check

We cross-check the current target families against Artificial Analysis before refreshing our bench.

Current takeaways:
- Gemini 3.1 Pro Preview is the intelligence headline model right now, which is why it stays on the bench despite messy tool behavior.
- GLM-5, Kimi K2.5, DeepSeek V3.2, and Grok 4.20 all remain relevant current families and all are already wired into this LiteLLM gateway.
- MiniMax naming is ahead of the public benchmark naming cadence: this gateway exposes newer `M2.7` routes while public benchmark references still often center on `M2.5`.

Practical conclusion:
- none of the model families we care about are missing from the current LiteLLM stack
- the current work is quality and behavior, not missing routes

## Model Selection Guide

### Recommended Default
- `vercel/minimax-m2.7-highspeed`

Use this if you want:
- the best current chance of a clean first experience
- strong value for money
- a route that actually finishes Codex tasks on this endpoint

### Experimental Frontier Option
- `vercel/gemini-3.1-pro-preview`

Use this if you want:
- a high-intelligence route that may improve quickly
- to test the edge of what the harness can tolerate

Do not use this as your default yet if you care about clean tool behavior.

### Keep On The Bench
- `vercel/glm-5-turbo`
- `vercel/kimi-k2.5`
- `vercel/deepseek-v3.2-thinking`
- `vercel/grok-4.20-reasoning-beta`

Use these only if you are actively testing or debugging the route.

### Side Option
- `vercel/claude-haiku-4.5`

This remains a reasonable low-cost side option, but it is not part of the current focus bench run.

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

Use the normal Codex home.

`codex-litellm` should only need two extra inputs over plain Codex:
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
model = "vercel/minimax-m2.7-highspeed"
```

Start the CLI:

```bash
codex-litellm
```

Or run one-shot commands:

```bash
codex-litellm exec "Summarize this repository"
codex-litellm exec "Refactor this function" --model vercel/minimax-m2.7-highspeed
```

## Run The Same Smoke Bench We Use

```bash
scripts/run-public-smoke-bench.sh --profile ~/.codex
```

Current focus models in the public bench:
- MiniMax
- GLM
- Kimi
- DeepSeek
- Gemini 3.1 Pro
- Grok 4.20 reasoning

The exact route for each family is discovered from your LiteLLM `/v1/models` inventory at runtime.

## Good First Commands

UI change:

```bash
codex-litellm exec "Change all primary buttons to pill-shaped gradient buttons" --model vercel/minimax-m2.7-highspeed
```

Code review:

```bash
codex-litellm exec "Review the last set of changes for bugs and regressions" --model vercel/minimax-m2.7-highspeed
```

Bugfix plus test:

```bash
codex-litellm exec "Find why this test is failing, fix it, and update the test if needed" --model vercel/minimax-m2.7-highspeed
```

Experimental frontier test:

```bash
codex-litellm exec "Refactor this module and explain the tradeoffs" --model vercel/gemini-3.1-pro-preview
```

## Semantic Cache

If your LiteLLM deployment supports semantic cache, use it.

The practical version is simple:
- back cache lookup with a cheap embedding model
- keep cache lookup cost near zero relative to a full reasoning-model turn

A good example shape is:
- `vercel/gemini-embedding-001`

The cache backend belongs in LiteLLM, not in `codex-litellm`, but the user outcome is straightforward:
- lower repeat-call cost
- better economics for iterative Codex loops
- almost-zero marginal cost for cache probes when the embedding route is cheap

## Common Pitfalls

- Do not start with non-agentic models.
- Do not assume `/v1/models` means a route is ready for Codex-style tasks.
- Do not assume the top benchmark model will give the cleanest tool loop.
- Do not assume DeepSeek is safe on `/responses` yet.
- Do not assume Kimi or GLM are green just because they are strong models in other contexts.
- Do not keep burning money on premium routes through a weak bridge path if the official harness would be better.

## Troubleshooting

If a model behaves badly:
1. Check that your LiteLLM gateway is reachable.
2. Check that the slug exists on `/v1/models`.
3. Run `scripts/run-public-smoke-bench.sh --profile ~/.codex`.
4. Retry with MiniMax before blaming the patchset.

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
