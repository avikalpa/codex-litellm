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

Create the normal Codex home and point it at LiteLLM:

```bash
mkdir -p ~/.codex
cat > ~/.codex/config.toml <<'EOF2'
[general]
model_provider = "litellm"
api_base = "http://localhost:4000"

[litellm]
api_key = "your-litellm-api-key"
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

Use a separate `CODEX_HOME` only when you are doing isolated debugging or development work.

## Model Slugs

The exact slugs come from your LiteLLM gateway inventory.

Check them with:

```bash
curl http://localhost:4000/v1/models | jq '.data[].id'
```

Typical examples look like:
- `vercel/minimax-m2.5`
- `vercel/kimi-k2.5`
- `openrouter/claude-sonnet-4.6`
- `openrouter/deepseek-v3.2-thinking`

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

## Troubleshooting

If a model behaves badly:

1. Check that the LiteLLM gateway is reachable.
2. Check that the model slug exists on `/v1/models`.
3. Retry with a known-good agentic model.
4. If the failure is model-specific, capture logs before changing code.

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
