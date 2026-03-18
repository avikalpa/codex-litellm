# codex-litellm

`codex-litellm` is upstream `openai/codex` plus a maintained patchset so the Codex CLI can run against a LiteLLM backend.

- Software license: Apache-2.0
- Documentation license: CC BY 4.0
- Upstream base currently tracked here: `rust-v0.115.0`

## What It Is

- Keeps the upstream Codex UX and tool loop.
- Routes model traffic through LiteLLM so one CLI can talk to many providers.
- Carries the extra runtime logic needed for non-OpenAI providers and models:
  - request shaping
  - retry/fallback handling
  - tool-call normalization
  - finalization nudges for weaker agentic models
  - minimal release telemetry and richer debug telemetry

This is not intended to become a permanent fork with its own product direction. The core job is to keep a reproducible patchset that can be moved forward to new stable upstream `rust-v*` tags.

## Install

```bash
npm install -g @avikalpa/codex-litellm
```

The installed command is:

```bash
codex-litellm
```

## Minimal Setup

Point the CLI at a LiteLLM gateway and use the normal Codex home by default.

```bash
mkdir -p ~/.codex
cat > ~/.codex/config.toml <<'EOF'
[general]
model_provider = "litellm"
api_base = "http://localhost:4000"

[litellm]
api_key = "your-litellm-api-key"
EOF
```

If you need debug isolation during development, use a temporary `CODEX_HOME`. That is for debugging only. Release confidence should come from the default `.codex` path working correctly.

## Basic Usage

Interactive:

```bash
codex-litellm
```

One-shot execution:

```bash
codex-litellm exec "Summarize this repository"
```

Pick a model explicitly:

```bash
codex-litellm exec "Refactor this function" --model vercel/bon-gour/minimax-m2.5
```

## Agentic Model Policy

`codex-litellm` is agentic-first.

- Primary target: models that can inspect a repo, use tools, edit files, and finalize reliably.
- Non-agentic models are deprecated compatibility paths.
- Release gates should use live agentic smoke tests, not just local builds.

Current release-gate details live in `agent_docs/MODEL_BEHAVIOR_TESTS.md`.

## Repository Layout

```text
AGENTS.md              Operator rules for agents working in this repo
agent_docs/            Operator-facing maintenance and release docs
build.sh               Reproducible release build script
stable-tag.patch       Maintained patchset against upstream Codex
scripts/               Packaging and release helpers
bin/                   npm launcher shim
```

The checked-out upstream tree at `codex/` is a local working checkout and is not the source of truth for releases by itself. The release patchset is `stable-tag.patch`.

## Development Workflow

Local development happens against the debug binary in the upstream checkout:

```bash
cd codex/codex-rs
cargo build --locked --bin codex
```

For a fresh test repo:

```bash
rm -rf ../../test-workspace
cd ../..
./setup-test-env.sh
```

After changes under `codex/`, regenerate the release patch from the pinned upstream tag:

```bash
cd codex
git diff rust-v0.115.0 > ../stable-tag.patch
```

Use the exact pinned upstream tag for the current base. Do not diff arbitrary local history.

## Release Workflow

- Release builds are done on GitHub Actions, not by shipping local build outputs.
- npm publishing happens from the GitHub release workflow.
- Do not publish from an older upstream base after a request to update to latest upstream.

The release/operator docs are in:

- `AGENTS.md`
- `agent_docs/PUBLISHING.md`
- `agent_docs/CURRENT_TASK.md`

## User-Facing Troubleshooting

If a model stalls or behaves oddly:

1. verify the LiteLLM gateway is reachable
2. verify the model slug exists on the LiteLLM `/v1/models` endpoint
3. retry with a known-good agentic model
4. if the issue is model-specific, capture logs from a debug run before changing code

## Licensing

- Software, patches, build scripts, package metadata, and shipped artifacts: `Apache-2.0`
- Documentation and operator guidance: `CC BY 4.0`
- Upstream base: `openai/codex` under `Apache-2.0`

See:

- `LICENSE`
- `LICENSE-docs-CC-BY-4.0.txt`
- `NOTICE`
