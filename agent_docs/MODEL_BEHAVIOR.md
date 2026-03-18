# LiteLLM Model Behavior

This file captures the durable behavior differences that matter when patching Codex for LiteLLM-backed models.

## Core Principle
LiteLLM makes many models look OpenAI-like, but it does not make them behave the same. `codex-litellm` therefore has to handle backend differences at four layers:
- request shaping
- tool-call compatibility
- turn completion/follow-up behavior
- UI rendering and telemetry

## Agentic First
- The primary target is agentic models that can inspect a repo, use tools, edit files, and send a final answer without manual nudges.
- Non-agentic models are compatibility paths. They may still be useful, but they are not the standard we optimize the product around.
- If agentic models regress, that is a release blocker.

## Known LiteLLM Failure Modes
- Some gateways reject fields that upstream Codex can send safely.
- Some models emit tool calls but never send a final assistant message.
- Some models continue exploring after already making the needed edit.
- Some models provide poor or inconsistent token usage accounting.
- Some models produce reasoning-like chatter that should be rendered as reasoning, not as normal assistant text.
- Model slugs, capability metadata, and supported tool schemas drift over time.

## Current Response-Loop Principles
- Prefer transient per-request instructions over permanently mutating conversation history when nudging a stuck turn.
- If the model already made the required repo edit, bias hard toward finalization instead of more reconnaissance.
- Keep follow-up logic observable. A hidden retry loop without telemetry is not maintainable.
- Do not silently normalize away a model failure unless the normalization is deterministic and logged.

## Rendering Principles
- Intermediate reasoning should render as reasoning, not as standard assistant output.
- The final answer should be clearly distinguishable from tool chatter and retry prompts.
- If we synthesize or force progress, that should be visible in telemetry and understandable from logs.

## Backend Investigation Order
When a model misbehaves, investigate in this order:
1. Did the gateway reject our request shape?
2. Did the model emit usable tool calls?
3. Did our runtime execute the tools and return outputs correctly?
4. Did we fail to ask the model to finish?
5. Did the UI mis-render a valid completion?

## Caching And Token Accounting
- Do not assume provider-side caching works like OpenAI's caching.
- Treat backend token usage as advisory unless validated.
- Context-window protection should rely on our own estimates when backend numbers are obviously unreliable.
- If we add or tune caching logic, document the measured behavior rather than the intended behavior.

## Model Curation
- Model allowlists are policy, not truth.
- Artificial Analysis and the gateway inventory are evidence sources, not guarantees.
- A model stays supported only if it continues to work in real `codex-litellm` tasks.
