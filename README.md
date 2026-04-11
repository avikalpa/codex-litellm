# codex-litellm

Use it with `npx`:

```bash
npx @avikalpa/codex-litellm
```

Or install it globally:

```bash
npm install -g @avikalpa/codex-litellm
```

`codex-litellm` is upstream Codex CLI with a maintained LiteLLM patchset.

It keeps the Codex agent loop, but lets you run it against agentic models from many providers through one LiteLLM gateway. The goal is to keep Codex usable over LiteLLM without asking users to learn a separate tool or maintain a long-lived fork.

- Software license: Apache-2.0
- Documentation license: CC BY 4.0
- Current upstream base: `rust-v0.120.0`
- Default LiteLLM runtime path: `/responses`

## 1. What This Project Is For

Official Codex is still the better choice when you want the official OpenAI-hosted harness, the cleanest flagship OpenAI path, and the least bridge complexity.

`codex-litellm` is for a different job:
- one Codex CLI talking to many providers through LiteLLM
- agentic repository editing with non-OpenAI models
- cost control and model experimentation without abandoning the Codex workflow
- a patchset that stays close to upstream instead of turning into a separate product line

This project is strongest when you want Codex as the interface and LiteLLM as the routing layer.

## 2. Install

Use `npx` if you want the lightest possible start:

```bash
npx @avikalpa/codex-litellm
```

Use a global install if you want the command available everywhere:

```bash
npm install -g @avikalpa/codex-litellm
```

This installs the command:

```bash
codex-litellm
```

The npm package downloads a prebuilt binary from GitHub Releases for your platform.

## 3. First-Time Setup

`codex-litellm` is meant to use the same default home as Codex: `~/.codex`.

That is intentional. The normal user path should not require a special debug-only `CODEX_HOME`.

The extra LiteLLM-specific inputs you usually need are:
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

Then define the LiteLLM provider and a default profile in `~/.codex/config.toml`:

```toml
[model_providers.litellm]
name = "LiteLLM"
base_url = "http://localhost:4000/v1"
env_key = "LITELLM_API_KEY"
wire_api = "responses"

[profiles.codex-litellm]
model = "vercel/minimax-m2.7-highspeed"
model_provider = "litellm"
```

For most users, this is enough to get started.

## 4. First Run

Start the interactive CLI:

```bash
codex-litellm
```

Or run a one-shot command:

```bash
codex-litellm exec "Summarize this repository"
codex-litellm exec "Refactor this function" --model vercel/minimax-m2.7-highspeed
```

If you already use plain `codex`, you can keep doing that. The two CLIs are meant to coexist.

## 5. Shared Sessions

`codex` and `codex-litellm` intentionally share the same session store under `~/.codex/sessions`.

That gives you one history, but two runtime defaults:
- `codex` keeps the plain Codex provider and model defaults
- `codex-litellm` keeps the LiteLLM provider and the `codex-litellm` profile defaults

When you resume an old session from the other CLI, the active executable stays in charge of how the next turn is routed.

Practical consequence:
- resuming a plain Codex session from `codex-litellm` keeps LiteLLM active
- resuming a LiteLLM session from `codex` keeps plain Codex active
- the two CLIs should not clobber each other's remembered default model

This is intentional: one shared history, with separate runtime defaults for each CLI.

## 6. Model Selection

The Codex harness rewards agentic behavior: models need to search, edit, stop at the right time, and return a final answer. A model that looks clever in benchmarks or chat demos may still be poor at Codex-style work.

Current recommendation on the LiteLLM `/responses` path:
- `Recommended default`: `vercel/minimax-m2.7-highspeed`
- `Recommended cheaper second option`: `vercel/claude-haiku-4.5`
- `Research lane`: `vercel/glm-5-turbo`, `vercel/gemini-3.1-pro-preview`, `vercel/grok-4.20-reasoning-beta`, `vercel/kimi-k2.5`
- `Blocked`: `vercel/deepseek-v3.2-thinking`

The practical reading is simple:
- start with MiniMax
- if you want a cheaper serious option, try Claude Haiku
- treat GLM, Gemini, Grok, and Kimi as research candidates, not default daily drivers
- do not spend time trying to force DeepSeek through this `/responses` stack until the bridge issue is fixed

### Why DeepSeek Is Marked Blocked

DeepSeek is currently blocked because the LiteLLM `/responses` bridge is not carrying its tool-follow-up turns cleanly enough for reliable Codex use. This is a bridge-path issue, not just a model-quality issue.

## 7. Economics

There is usually little value in routing an expensive flagship model through a weak bridge path.

If your real goal is the best possible flagship OpenAI Codex experience, the official harness is usually better value:
- fewer moving parts
- fewer provider quirks
- less time burned debugging the transport instead of doing work

`codex-litellm` is strongest when you want:
- model choice
- pricing flexibility
- multi-provider experimentation
- good agentic behavior from non-OpenAI routes

Practical spending advice:
- if you want the safest default here, spend on MiniMax first
- if you want a cheaper serious lane, try Claude Haiku before escalating to more expensive research models
- treat GLM, Gemini, Grok, and Kimi as measured experiments, not daily-driver defaults
- do not spend money re-proving DeepSeek on the current `/responses` stack until the bridge issue is fixed
- if you are mainly chasing flagship-quality output rather than multi-provider flexibility, use official Codex instead of paying an indirection tax here

Use the route that gives you the best result for the money and operational complexity.

## 8. Semantic Cache

If your LiteLLM deployment supports semantic cache, use it.

The practical pattern is:
- keep the expensive reasoning model for actual turns
- use a cheap embedding route for cache lookup

A good shape is:
- `vercel/gemini-embedding-001`

Why this matters:
- cache probes become almost zero-cost relative to a full agentic turn
- repeated repo-edit loops cost less
- you get the benefit at the LiteLLM layer without adding more cache logic inside `codex-litellm`

## 9. `/responses` Is The Supported Path

`codex-litellm` now treats LiteLLM `/responses` as the default forward path.

That means:
- new work is validated against `/responses`
- model curation is based on `/responses` behavior
- known-broken routes are documented plainly instead of hidden behind fallback folklore

A route should only be treated as supported if it works on the path users are expected to run.

## 10. How We Judge Models

These ratings come from live `codex-litellm` runs through the Codex harness, not benchmark claims, API checks, or chat impressions.

A model is only useful here if it can:
- inspect a real repository
- use tools correctly
- make a real repo diff
- stop after the edit instead of looping forever
- return a final assistant answer

Good benchmark scores are not enough.

### Benchmarks vs Reality

We do look at benchmark data, especially Artificial Analysis, but only as an intake signal.

Benchmarks are useful for:
- deciding which newly available models are worth paying to probe
- spotting which providers are moving quickly on agentic behavior
- avoiding obviously stale or weak candidates

Benchmarks are not enough for:
- proving tool-use quality
- proving stop/finalize discipline after an edit
- proving the LiteLLM `/responses` bridge is stable for that route
- proving the model is worth its price on real repository work

Benchmark rank can earn a model a place on the research bench, but only live repo-edit runs can earn it a recommendation.

### Current Results

If you just want the short version:
- use MiniMax first
- use Claude Haiku when you want the cheaper serious option
- treat GLM, Gemini, Grok, and Kimi as research lanes
- treat DeepSeek as blocked on the current `/responses` stack

The table below summarizes current live results.

| Model | `mini-web` | `python-cli` | `calibre-web` exploratory | What usually goes wrong | Current recommendation |
| --- | --- | --- | --- | --- | --- |
| `vercel/minimax-m2.7-highspeed` | PASS | PASS | FAIL under route pressure, no clean diff on the latest heavy probe | larger repos currently amplify retry or 429 noise | recommended default |
| `vercel/claude-haiku-4.5` | PASS | PASS | not yet cleanly completed in the latest heavy probe batch | needs more large-repo evidence | recommended cheaper second option |
| `vercel/glm-5-turbo` | FAIL | FAIL | FAIL | retry and 429 noise before a useful diff | research lane only |
| `vercel/gemini-3.1-pro-preview` | EDITS, THEN STALLS | TIMEOUT | blocked by current gateway credits on the latest heavy probe | post-edit finalization is still too weak, and heavy-repo results are currently confounded by billing state | watchlist only |
| `vercel/grok-4.20-reasoning-beta` | PASS | FAIL | incomplete probe | can look strong on light UI work, then fail to produce a qualifying diff on procedural work | watchlist only |
| `vercel/kimi-k2.5` | FAIL | PASS | blocked by current gateway credits on the latest heavy probe | behavior is fixture-sensitive; it handles procedural edits better than broad UI hunting | research lane only |
| `vercel/deepseek-v3.2-thinking` | BLOCKED | BLOCKED | not worth probing further until bridge fix | LiteLLM `/responses` tool-follow-up incompatibility | blocked on this stack |

### What The Labels Mean

- `PASS` means the model completed a Codex-harness run with a real repo diff and a final answer.
- `EDITS, THEN STALLS` means the model found the right change, but did not exit cleanly enough to be trustworthy.
- `FAIL` means it either never produced the required diff or collapsed into retries, rate limits, or a no-op finish.
- `BLOCKED` means the problem is below normal model quality. The current bridge path is incompatible.

## 11. Research Bench

The repository includes a public smoke bench that:
- resolves live model IDs from your LiteLLM `/v1/models`
- sanitizes private route segments before writing public output
- runs real Codex-harness repo-edit tasks, not toy prompt checks
- refuses to call a run a pass unless it produces a non-empty repo diff

The active fixtures are intentionally different:
- `mini-web` checks whether a model can inspect, edit, and finalize a concrete UI restyle
- `python-cli` requires diffs in the CLI file, the README, and the test file, so partial edits do not count as a pass
- `calibre-web` is the heavier real-world probe for large-repo search, edit discipline, and route stability

This bench helps us:
- separate “sounds smart” from “can finish Codex work”
- measure whether a model is worth its route cost
- catch regressions in the LiteLLM bridge before users do
- build evidence strong enough to block or allow release lanes

Current takeaways:
- MiniMax is still the best overall default on this stack because it clears the harness often enough to justify its cost.
- Claude Haiku is the best cheaper second option so far.
- Kimi, GLM, Gemini, and Grok have shown promise, but they are still bench-dependent rather than operationally stable.
- DeepSeek remains blocked by the current `/responses` bridge, so more paid probing there has low return.
- Heavier repos matter; some models that look fine on `mini-web` degrade sharply when the task shifts to larger search spaces and stricter edit discipline.

If you care about benchmark-style content, the project’s position is:
- we use benchmarks to choose what to test
- we use Codex-harness repo-edit runs to decide what to recommend
- we use cost and completion quality together, not benchmark rank alone

Run the public bench with:

```bash
scripts/run-public-smoke-bench.sh --profile ~/.codex
```

## 12. Troubleshooting

If a model behaves badly:
1. Confirm your LiteLLM gateway is reachable.
2. Confirm the route exists on `/v1/models`.
3. Retry with MiniMax before blaming the patchset.
4. Run `scripts/run-public-smoke-bench.sh --profile ~/.codex`.

If install fails:
1. Verify GitHub Releases is reachable.
2. Re-run `npm install -g @avikalpa/codex-litellm`.
3. If your platform is unsupported, build from source.

Common mistakes:
- starting with non-agentic models
- assuming `/v1/models` availability means Codex-harness readiness
- reading benchmark rank as proof of tool-use quality
- spending premium-model money through a route that is already known to be weak

## 13. Build From Source

For local testing, do not use `build.sh`. That is release automation and resets the upstream checkout.

Fastest local debug build:

```bash
./scripts/build-local-fast.sh
```

Run it from the repo root with the launcher:

```bash
./codex-litellm
```

Or run the binary directly from the upstream workspace target dir:

```bash
./codex/codex-rs/target/debug/codex-litellm
```

Notes:
- `./target/debug/codex-litellm` from the repo root is the wrong path
- `../codex/codex-rs/target/debug/codex-litellm` is the wrong path from this repo; that points outside this checkout
- the helper enables incremental builds and uses `sccache` automatically if it is installed
- keep `codex/codex-rs/target/` around between builds; that is where most of the speedup comes from

## 14. For Developers

User-facing docs live in `README.md`.

Operator-facing docs live in:
- `AGENTS.md`
- `agent_docs/`

If user-facing behavior changes, update `README.md` and the changelog to match.
