# LiteLLM Model Behavior

This file captures the durable behavior differences that matter when patching Codex for LiteLLM-backed models.

## Core Principle
LiteLLM makes many models look OpenAI-like, but it does not make them behave the same. `codex-litellm` therefore has to handle backend differences at four layers:
- request shaping
- tool-call compatibility
- model discovery
- release validation

## Agentic First
- The primary target is agentic models that can inspect a repo, use tools, edit files, and send a final answer without manual nudges.
- Non-agentic models are compatibility paths. They may still be useful, but they are not the standard we optimize the product around.
- If agentic models regress, that is a release blocker.

## Known LiteLLM Failure Modes
- Some gateways reject fields that upstream Codex can send safely.
- Some models emit tool calls but do not finish cleanly.
- Some models continue exploring after already making the needed edit.
- Model slugs, capability metadata, and supported tool schemas drift over time.

## Current Response-Loop Principles
- Use upstream Codex defaults for context management and conversation handling.
- Keep LiteLLM-specific request shaping narrow and deterministic.
- Do not silently normalize away a model failure unless the normalization is clear from the code and release evidence.
- Treat `/responses` behavior as the supported path; do not add new `/chat/completions` work.

## Backend Investigation Order
When a model misbehaves, investigate in this order:
1. Did the gateway reject our request shape?
2. Did the model emit usable tool calls?
3. Did our runtime execute the tools and return outputs correctly?
4. Did we fail to ask the model to finish?
5. Did the UI mis-render a valid completion?

## Model Curation
- Model allowlists are policy, not truth.
- Artificial Analysis and the gateway inventory are evidence sources, not guarantees.
- A model stays supported only if it continues to work in real `codex-litellm` tasks.
