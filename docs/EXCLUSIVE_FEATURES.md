# Codex LiteLLM Deltas

These are the project-specific capabilities layered on top of upstream Codex.

## Functional Deltas
- direct LiteLLM backend support
- runtime compatibility handling for heterogeneous model/provider behavior
- extra telemetry for debugging request, tool, and rendering regressions
- model curation and deprecation policy tuned for LiteLLM backends
- release packaging and npm distribution for the patched binary

## Operational Deltas
- telemetry under `${CODEX_HOME}/logs`
- local context-usage protection where backend usage reporting is unreliable
- release metadata and patchset management from the root repo

These deltas should stay as small and as maintainable as possible. If an upstream feature makes one unnecessary, remove our version.
