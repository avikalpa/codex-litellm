# codex-litellm

`codex-litellm` is upstream Codex CLI with a maintained LiteLLM patchset.

It keeps the Codex agent loop, but lets you run it against agentic models from many providers through one LiteLLM gateway.

- Software license: Apache-2.0
- Documentation license: CC BY 4.0
- Current upstream base: `rust-v0.116.0`
- Default runtime path: LiteLLM `/responses`

## What This Is

Official Codex is still the right answer when you want the official hosted harness and the best-supported OpenAI path.

`codex-litellm` is for a different job:
- one Codex CLI talking to many providers through LiteLLM
- agentic repo editing with non-OpenAI models
- fast model experimentation without abandoning the Codex workflow
- a patchset that stays close to upstream instead of becoming a permanent fork

## Current Recommendation

Start with MiniMax.

Current agentic shortlist on the LiteLLM `/responses` path:
- Green: `vercel/minimax-m2.7-highspeed`
- Green: `vercel/claude-haiku-4.5`
- Amber: `vercel/glm-5-turbo`
- Watchlist: `vercel/gemini-3.1-pro-preview`
- Watchlist: `vercel/grok-4.20-reasoning-beta`
- Red: `vercel/kimi-k2.5`
- Blocked: `vercel/deepseek-v3.2-thinking`

What those labels mean here:
- `Green`: made a real repo edit and completed cleanly
- `Amber`: promising, but still unstable or economically noisy on this endpoint
- `Watchlist`: worth continued testing, but not stable enough to recommend as a default route yet
- `Red`: not reliable enough for Codex-style editing on this endpoint today
- `Blocked`: failing at the LiteLLM `/responses` bridge layer rather than only at model quality

## Feasibility By Model

These ratings come from live `codex-litellm` runs against the current LiteLLM gateway, not benchmark claims.

| Model | `mini-web` explicit restyle | `python-cli` strict multi-file task | Current recommendation |
| --- | --- | --- | --- |
| `vercel/minimax-m2.7-highspeed` | pass | pass | best default |
| `vercel/claude-haiku-4.5` | pass | pass | best cheaper second option |
| `vercel/glm-5-turbo` | edit, but noisy / retries | not yet revalidated | test carefully |
| `vercel/gemini-3.1-pro-preview` | correct edit, then stalled | fail under rate-limit pressure | watchlist only |
| `vercel/grok-4.20-reasoning-beta` | pass | fail under rate-limit pressure | watchlist only |
| `vercel/kimi-k2.5` | fail, no repo diff | not worth promoting yet | avoid for now |
| `vercel/deepseek-v3.2-thinking` | blocked | blocked by same bridge class | blocked on this stack |

What this means in practice:
- if you want the highest first-run odds, use `vercel/minimax-m2.7-highspeed`
- if you want a cheaper serious option, try `vercel/claude-haiku-4.5`
- if you want to experiment, keep `vercel/gemini-3.1-pro-preview` and `vercel/grok-4.20-reasoning-beta` in the bench, not as defaults
- do not spend time debugging `vercel/deepseek-v3.2-thinking` on this stack until the LiteLLM `/responses` tool-follow-up bug is fixed

## What We Mean By “Agentic”

A model is only useful here if it can:
- inspect a repo
- use tools correctly
- make a real file edit
- stop after the edit
- return a final assistant answer

Good benchmark scores are not enough.

## Model Selection

### Best Default
- `vercel/minimax-m2.7-highspeed`

Why:
- currently the cleanest edit loop on this gateway
- good price/performance
- clears both the lightweight UI fixture and the stricter multi-file CLI fixture

### Best Secondary Option
- `vercel/claude-haiku-4.5`

Why:
- now clears both the explicit `mini-web` restyle task and the stricter `python-cli` task
- cheaper than many frontier alternatives
- materially better current evidence than Gemini, Grok, Kimi, or DeepSeek on this stack

### Worth Testing Next
- `vercel/glm-5-turbo`
- `vercel/claude-haiku-4.5`
- `vercel/gemini-3.1-pro-preview`
- `vercel/grok-4.20-reasoning-beta`

Why they are not defaults yet:
- GLM can edit, but the current route still shows retry/rate-limit noise on this endpoint
- Gemini 3.1 Pro Preview makes the right edit on this fixture, but the current route still stalls too long after the diff
- Grok 4.20 now passes the explicit fixture prompt, but it still belongs in the watchlist lane until it proves itself on broader repos

### Do Not Start Here
- `vercel/kimi-k2.5`
- `vercel/deepseek-v3.2-thinking`

Why:
- Kimi still fails to produce dependable repo diffs in the current bench
- DeepSeek is still blocked by the current LiteLLM `/responses` tool-follow-up bridge on this endpoint

### Economics Warning

If you want to spend premium money on expensive frontier models, ask whether LiteLLM is adding value for that run.

If the goal is simply “best possible flagship Codex experience”, the official harness is usually the better value:
- less bridge complexity
- fewer provider quirks
- less money wasted debugging endpoint behavior instead of doing work

`codex-litellm` is strongest when you want:
- model choice
- cost control
- experimentation across providers
- good-enough agentic performance from non-OpenAI routes

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

Use the normal Codex home at `~/.codex`.

The intended UX is that `codex-litellm` only needs two LiteLLM-specific inputs beyond plain Codex:
- `LITELLM_BASE_URL`
- `LITELLM_API_KEY`

Put them in `~/.codex/.env`:

```bash
mkdir -p ~/.codex
cat > ~/.codex/.env <<'EOF2'
LITELLM_BASE_URL=http://localhost:4000/v1
LITELLM_API_KEY=your-litellm-api-key
EOF2
```

Then configure the LiteLLM provider in `~/.codex/config.toml`:

```toml
[model_providers.litellm]
name = "LiteLLM"
base_url = "http://localhost:4000/v1"
env_key = "LITELLM_API_KEY"
wire_api = "responses"

[profiles.codex-litellm]
model = "vercel/minimax-m2.7-highspeed"
```

Why the dedicated profile matters:
- plain `codex` and `codex-litellm` can share `~/.codex`
- the remembered model choice lives under the `codex-litellm` profile instead of stomping the default Codex model selection

Start the CLI:

```bash
codex-litellm
```

Or run one-shot commands:

```bash
codex-litellm exec "Summarize this repository"
codex-litellm exec "Refactor this function" --model vercel/minimax-m2.7-highspeed
```

## `/responses` Is The Supported Path

`codex-litellm` now treats LiteLLM `/responses` as the forward path.

That means:
- new work is validated against `/responses`
- model curation is based on `/responses` behavior
- known-broken `/responses` routes are documented plainly instead of hidden behind fallback magic

DeepSeek is the clearest current example:
- the model family matters
- but the current blocker here is the LiteLLM `/responses` bridge for tool-follow-up turns
- until that bridge is fixed, DeepSeek is not a recommended Codex route on this stack

## Semantic Cache

If your LiteLLM deployment supports semantic cache, use it.

The practical pattern is:
- keep the expensive reasoning model for actual turns
- use a cheap embedding route for cache lookup

A good shape is:
- `vercel/gemini-embedding-001`

Why this matters:
- cache probes become almost zero-cost relative to a full agentic turn
- repeated repo-edit loops cost less
- you get the benefit at the LiteLLM layer without adding more cache logic to `codex-litellm`

## Smoke Bench

The repository includes a public smoke bench that:
- resolves live model IDs from your LiteLLM `/v1/models`
- sanitizes private route segments before writing public output
- runs a real repo-edit task on a small fixture
- refuses to call a run a pass unless it produces a non-empty repo diff

Current active bench focus:
- `vercel/minimax-m2.7-highspeed`
- `vercel/glm-5-turbo`
- `vercel/kimi-k2.5`
- `vercel/claude-haiku-4.5`

Current watchlist bench:
- `vercel/gemini-3.1-pro-preview`
- `vercel/grok-4.20-reasoning-beta`

DeepSeek is tracked separately as a blocked `/responses` route, not as a default public bench candidate.

The fixture gates are intentionally different:
- `mini-web` checks whether a model can inspect, edit, and finalize a concrete UI restyle
- `python-cli` now requires diffs in the CLI file, the README, and the test file, so partial edits do not count as a pass

Run it with:

```bash
scripts/run-public-smoke-bench.sh --profile ~/.codex
```

## Common Pitfalls

- Do not start with non-agentic models.
- Do not assume a model listed on `/v1/models` is ready for Codex-style work.
- Do not assume benchmark rank means good tool behavior.
- Do not assume Kimi or Claude Haiku are green just because they are strong model families.
- Do not assume Gemini 3.1 Pro Preview or Grok 4.20 are default-safe just because they are strong frontier families.
- Do not assume DeepSeek is usable on this LiteLLM `/responses` bridge today.
- Do not spend premium-model money through a weak bridge path when the official harness would do the job better.

## Troubleshooting

If a model behaves badly:
1. Confirm your LiteLLM gateway is reachable.
2. Confirm the route exists on `/v1/models`.
3. Retry with MiniMax before blaming the patchset.
4. Run `scripts/run-public-smoke-bench.sh --profile ~/.codex`.

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
- economics versus hype
- portability of the patchset to the next stable upstream tag

## For Developers

User-facing docs live here in `README.md`.

Operator docs live in:
- `AGENTS.md`
- `agent_docs/`
