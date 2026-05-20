# Upstream Logic To Preserve

This file exists to capture upstream Codex behavior that our LiteLLM patchset should preserve unless LiteLLM compatibility requires a deliberate divergence.

## Preserve By Default
- reasoning is rendered as reasoning, not as ordinary assistant output
- the final answer is distinct from intermediate tool chatter
- status/header updates should feel like Codex, not like a different product
- context management should follow upstream Codex defaults unless there is fresh evidence of a LiteLLM-specific regression

## Acceptable Divergences
- request shaping needed for LiteLLM compatibility
- local tool-schema normalization when gateways reject upstream shapes
- LiteLLM `/v1/models` discovery and model-selection policy
- first-run LiteLLM setup
- minimal diagnostics needed to explain release-blocking model failures

## Rule Of Thumb
If a change is only there to paper over one model or provider quirk, keep it narrow, observable, and easy to revisit on the next upstream refresh.
