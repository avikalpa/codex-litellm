# codex-litellm

`codex-litellm` is the Codex CLI, patched to run against a LiteLLM backend.

It keeps the upstream Codex agent workflow, but lets you use models from multiple providers through one gateway.

- Software license: Apache-2.0
- Documentation license: CC BY 4.0
- Current upstream base: `rust-v0.115.0`

## Why Use It

Use `codex-litellm` if you want Codex-style repo editing and tool use, but you do not want to be limited to OpenAI-hosted models.

It is built for:
- one Codex CLI talking to many providers through LiteLLM
- agentic coding models that can search, edit, run commands, and finish cleanly
- staying close to upstream Codex instead of becoming a permanent fork

## What Works Best Today

`codex-litellm` is agentic-first and the supported path is LiteLLM `/responses`.

Current known status on `/responses`:
- green: `vercel/minimax-m2.5`
- green: `vercel/kimi-k2.5`
- blocked: `vercel/deepseek-v3.2-thinking`

DeepSeek is currently blocked because the LiteLLM/Vercel bridge rejects some tool-use follow-up turns with missing `reasoning_content`.

Non-agentic models are deprecated. They may still run, but they are not the product center and are not release gates.

## Choose A Model First

Start with agentic models.

Best current verified starting points for `codex-litellm` are:
- `vercel/minimax-m2.5`
- `vercel/kimi-k2.5`

Strong next models to try, if your LiteLLM gateway exposes good routes for them, are:
- `vercel/claude-haiku-4.5`
- `glm-5` if your LiteLLM gateway exposes an agentic GLM route

Use those before trying frontier-priced models.

Practical rule:
- if you want maximum value for money inside `codex-litellm`, start with MiniMax, Kimi, Haiku, or GLM-class agentic models
- if you intend to spend premium-tier tokens on an expensive flagship model, you may get better value from the official provider or official Codex path instead of paying bridge overhead for a generic LiteLLM route

This project is optimized for good agent loops on a wide model surface, not for making the most expensive models economically attractive.

## Install

```bash
npm install -g @avikalpa/codex-litellm
```

This installs the command:

```bash
codex-litellm
```

The npm package downloads the correct prebuilt binary for your platform from GitHub Releases.

## Quick Start

Use the normal Codex home.

Over plain upstream Codex, `codex-litellm` should only need two extra inputs:
- your LiteLLM `/v1` base URL
- your LiteLLM API key

The intended default is to keep those in `~/.codex/.env`:

```bash
mkdir -p ~/.codex
cat > ~/.codex/.env <<'EOF2'
LITELLM_BASE_URL=http://localhost:4000/v1
LITELLM_API_KEY=your-litellm-api-key
EOF2
```

If you want a default model for `codex-litellm`, add it under its dedicated
profile so plain `codex` does not get its model selection overwritten:

```bash
cat > ~/.codex/config.toml <<'EOF2'
[profiles.codex-litellm]
model = "vercel/minimax-m2.5"
EOF2
```

Then start the CLI:

```bash
codex-litellm
```

One-shot execution:

```bash
codex-litellm exec "Summarize this repository"
```

Pick a model explicitly:

```bash
codex-litellm exec "Refactor this function" --model vercel/minimax-m2.5
```

## Recommended Setup

Default behavior should work directly with your normal `~/.codex` directory.

That is the path we care about most.

`codex-litellm` automatically uses the hidden `codex-litellm` profile for its
remembered model state, so it does not clobber plain `codex` model state in
the same home directory.

If you prefer storing the LiteLLM endpoint in `config.toml` instead of
`~/.codex/.env`, use the built-in provider override shape:

```toml
[model_providers.litellm]
name = "LiteLLM"
base_url = "http://localhost:4000/v1"
env_key = "LITELLM_API_KEY"
wire_api = "responses"
```

Keep the API key in `~/.codex/.env` as `LITELLM_API_KEY` unless you have a very
specific reason not to. That keeps the shared config file cleaner and avoids
teaching users to commit secrets to TOML.

Use a separate `CODEX_HOME` only when you are doing isolated debugging or development work.

If a setup requires a special debug-only home to work, treat that as a bug, not the intended user path.

## Model Slugs

The exact slugs come from your LiteLLM gateway inventory.

Check them with:

```bash
curl http://localhost:4000/v1/models | jq '.data[].id'
```

Typical examples look like:
- `vercel/minimax-m2.5`
- `vercel/kimi-k2.5`
- `vercel/claude-haiku-4.5`
- `openrouter/claude-sonnet-4.6`
- `openrouter/deepseek-v3.2-thinking`

Do not assume a model is a good fit just because it appears on `/v1/models`.

For `codex-litellm`, the important question is whether the model can:
- use tools correctly
- edit the repo instead of wandering
- stop after the edit and produce a final answer

That is why model selection matters more here than in a plain chat UI.

## Good First Commands

Ask for a repo change:

```bash
codex-litellm exec "Change all primary buttons to pill-shaped gradient buttons" --model vercel/minimax-m2.5
```

Ask for code review:

```bash
codex-litellm exec "Review the last set of changes for bugs and regressions" --model vercel/kimi-k2.5
```

Use the interactive TUI:

```bash
codex-litellm --model vercel/minimax-m2.5
```

## Common Pitfalls

- Do not start with non-agentic models. They often fail mid-loop, never finalize, or burn tokens on weak tool behavior.
- Do not assume DeepSeek is ready just because the slug exists. It is currently a known bad path for release-grade `/responses` use.
- Do not overpay for premium models unless you have a concrete reason. `codex-litellm` is best when paired with strong-but-efficient agentic models.
- Do not build your workflow around a custom debug `CODEX_HOME`. The intended path is the normal `~/.codex` directory.

## Semantic Cache

If your LiteLLM deployment supports semantic caching, use it.

LiteLLM supports semantic cache lookup with an embedding model. In practice, you should choose a cheap embedding model so cache lookup cost stays negligible relative to the main model call.

If your gateway exposes a Gemini embedding route, that is usually a good default because it is materially cheaper than burning another full reasoning-model round trip for repeated prompts.

Example slug shape:
- `vercel/gemini-embedding-001`

The exact cache backend and embedding model setup belongs in your LiteLLM deployment, not in `codex-litellm` itself.

## Troubleshooting

If a model behaves badly:

1. Check that the LiteLLM gateway is reachable.
2. Check that the model slug exists on `/v1/models`.
3. Retry with a known-good agentic model like MiniMax or Kimi.
4. If the failure is model-specific, capture logs before changing code.

If a model is expensive and still underperforms:

1. Stop burning tokens on it through a weak bridge path.
2. Try a cheaper verified agentic model first.
3. If you truly need that premium model, consider using the official harness for that provider instead.

If install fails:

1. Verify GitHub Releases is reachable from the machine.
2. Re-run `npm install -g @avikalpa/codex-litellm`.
3. If your platform is unsupported, build from source.

If the binary is missing after install:

```bash
npm install -g @avikalpa/codex-litellm
```

## Project Direction

This project is intentionally narrow.

The goal is not to reinvent Codex. The goal is to keep a maintained patchset that makes upstream Codex work well with LiteLLM, provider diversity, and real agentic models.

That means the project focuses on:
- LiteLLM compatibility
- provider and model quirks
- agentic model validation
- minimal release telemetry
- keeping the patchset portable to newer upstream stable tags

## For Developers

The user-facing docs stop here. Operator and maintenance docs live in:
- `AGENTS.md`
- `agent_docs/PUBLISHING.md`
- `agent_docs/CURRENT_TASK.md`
- `agent_docs/MODEL_BEHAVIOR_TESTS.md`

Local development uses the upstream checkout in `codex/`, but releases are built on GitHub Actions and published from CI.

## Licensing

- Software, patches, build scripts, package metadata, and shipped artifacts: `Apache-2.0`
- Documentation and maintenance docs: `CC BY 4.0`
- Upstream base: `openai/codex` under `Apache-2.0`

See:
- `LICENSE`
- `LICENSE-docs-CC-BY-4.0.txt`
- `NOTICE`
