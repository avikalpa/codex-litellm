# Changelog

This file tracks user-visible changes in `codex-litellm`.

## Unreleased
### Highlights
- Moved the project docs to a shorter operator-focused structure so release, telemetry, and model-validation guidance reflects the current LiteLLM workflow instead of stale historical assumptions.
- Kept the `0.115.0` upstream refresh as the active release line and documented the current agentic release blocker explicitly.

### Detailed Changes
- docs: rewrote `AGENTS.md` around the actual patchset workflow, upstream refresh rules, release gating, and LiteLLM-specific engineering priorities.
- docs: replaced stale version-pinned process notes across `agent_docs/` with current guidance for publishing, telemetry, supported models, patch maintenance, and live model validation.

## Format
Use VS Code-style release notes:
- short intro paragraph
- `Highlights`
- `Detailed Changes`
