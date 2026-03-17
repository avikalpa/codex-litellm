# Supported Models (Agentic-First)

This project now prioritizes agentic models and treats non-agentic models as deprecated for `codex-litellm`.

## Active allowlist (agentic-first)

- `gpt-5.4`, `gpt-5.4-pro`, `gpt-5.3-codex`
- `claude-sonnet-4.6`, `claude-opus-4.6`
- `gemini-3.1-pro-preview`, `gemini-3-pro`, `gemini-3-flash`
- `grok-4.1-fast-reasoning`
- `deepseek-v3.2-thinking`
- `minimax-m2.5`
- `kimi-k2.5`

## Policy

- New model additions must be agentic-first.
- Non-agentic models (including `gpt-oss-*`) are not included in the picker allowlist for `codex-litellm`.
- If no allowlisted model is available from the backend, the CLI falls back to upstream model discovery to avoid hard failure.
- Prefer the gateway's canonical slugs when they differ from Artificial Analysis punctuation. The matcher normalizes `.` to `-`, so endpoint slugs like `gpt-5.4` still match AA slugs like `gpt-5-4`.
- `deepseek-v3.2-thinking` is intentionally allowlisted because the gateway serves that slug while Artificial Analysis currently catalogs the corresponding family under `deepseek-v3-2-reasoning`.

## Source of truth

- Candidate modern model names are discovered via Chromium automation against `https://artificialanalysis.ai/`.
- Refresh the AA evidence with `node scripts/artificialanalysis-harness.cjs` (set `NODE_PATH` if Playwright is installed into a non-default prefix).
- Latest captured slug sweep (Playwright/Chromium): `logs/artificialanalysis-model-slugs.json`.
- Latest agentic-loop evidence capture: `logs/aa-agentic-click-report.json`.
- Latest LiteLLM endpoint inventory snapshot: `logs/litellm-models.json`.
