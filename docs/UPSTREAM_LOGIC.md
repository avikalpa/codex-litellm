# Upstream Logic To Preserve

This file exists to capture upstream Codex behavior that our LiteLLM patchset should preserve unless LiteLLM compatibility requires a deliberate divergence.

## Preserve By Default
- reasoning is rendered as reasoning, not as ordinary assistant output
- the final answer is distinct from intermediate tool chatter
- status/header updates should feel like Codex, not like a different product
- token and context displays should remain useful even if our implementation has to estimate more locally than upstream

## Acceptable Divergences
- request shaping needed for LiteLLM compatibility
- local tool-schema normalization when gateways reject upstream shapes
- follow-up/finalization nudges for models that stall after tools
- telemetry and observability additions that upstream does not ship
- model-selection policy that is stricter than upstream because LiteLLM model quality is heterogeneous

## Rule Of Thumb
If a change is only there to paper over one model or provider quirk, keep it narrow, observable, and easy to revisit on the next upstream refresh.
