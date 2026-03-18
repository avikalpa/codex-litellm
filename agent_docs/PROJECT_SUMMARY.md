# Project Summary

## What This Repo Is
`codex-litellm` is a patchset that keeps upstream Codex usable against a LiteLLM backend. It is not a separate product with its own independent architecture.

## What We Add Beyond Upstream
- direct LiteLLM request/response compatibility
- provider/model-specific runtime fixes
- extra telemetry for debugging heterogeneous backends
- supported-model curation and release gating based on real model behavior
- packaging and publish automation for the patched binary

## What Makes This Project Hard
- upstream Codex evolves quickly
- LiteLLM behavior changes over time
- providers expose different subsets of tool-calling behavior
- some models reason well but do not finalize
- some models work only with request-shape or rendering adjustments

## Working Philosophy
- stay close to upstream
- patch only where LiteLLM or model behavior requires it
- prefer evidence over theory
- treat model support as a living compatibility matrix, not a static promise
- keep the release path reproducible
