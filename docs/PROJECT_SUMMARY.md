# Project Summary

## What This Repo Is
`codex-litellm` is a patchset that keeps upstream Codex usable against a LiteLLM backend. It is not a separate product with its own independent architecture.

## What We Add Beyond Upstream
- direct LiteLLM `/responses` compatibility
- LiteLLM first-run setup in the `codex-litellm` binary
- LiteLLM `/v1/models` discovery in `/model`
- narrow request/tool compatibility handling for heterogeneous backends
- supported-model guidance and release gating based on real model behavior
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
- rely on upstream Codex context-management defaults unless live evidence proves a regression
