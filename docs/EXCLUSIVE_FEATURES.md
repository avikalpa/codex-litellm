# Codex LiteLLM Deltas

These are the project-specific capabilities layered on top of upstream Codex.

## Functional Deltas
- direct LiteLLM backend support
- runtime compatibility handling for heterogeneous model/provider behavior
- LiteLLM `/v1/models` discovery in the `/model` selector
- first-run setup for LiteLLM base URL, API key, and optional default model
- model curation guidance tuned for LiteLLM backends
- release packaging and npm distribution for the patched binary

## Operational Deltas
- release validation against live LiteLLM `/responses` behavior
- release metadata and patchset management from the root repo

These deltas should stay as small and as maintainable as possible. If an upstream feature makes one unnecessary, remove our version.
