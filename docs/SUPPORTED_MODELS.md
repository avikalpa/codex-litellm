# Supported Models (Agentic-First)

This project now prioritizes agentic models and treats non-agentic models as deprecated for `codex-litellm`.

## Active allowlist (agentic-first)

- `gpt-5.2-codex`
- `gpt-5.2`
- `gpt-5.1-codex-max`
- `gpt-5.1-codex-mini`
- `gpt-5.1`
- `gpt-5`
- `o3`, `o3-pro`, `o4-mini`
- `claude-sonnet-4-6`, `claude-4-5-sonnet`
- `gemini-3-pro`
- `grok-4-1-fast-reasoning`
- `deepseek-v3-2-reasoning`
- `minimax-m2-5`, `minimax-m2`
- `kimi-k2-5`, `kimi-k2.5`
- `qwen3-5-397b-a17b`
- `glm-5`

## Policy

- New model additions must be agentic-first.
- Non-agentic models (including `gpt-oss-*`) are not included in the picker allowlist for `codex-litellm`.
- If no allowlisted model is available from the backend, the CLI falls back to upstream model discovery to avoid hard failure.

## Source of truth

- Candidate modern model names are discovered via Chromium automation against `https://artificialanalysis.ai/`.
- Latest captured slug sweep (Playwright/Chromium): `logs/artificialanalysis-model-slugs.json`.
