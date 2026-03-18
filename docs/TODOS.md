# TODOs

## Release-Critical
- [ ] Make the `0.115.0` agentic gate (`vercel/bon-gour/minimax-m2.5`) terminate cleanly after successful edits.
- [ ] Re-run the non-agentic compatibility check on `vercel/bon-gour/gpt-oss-120b` after the agentic finalize path is stable.
- [ ] Regenerate `stable-tag.patch` from the final `0.115.0` state before the release commit.

## Model Runtime
- [ ] Keep tightening post-edit finalization so agentic models stop exploring once the requested change is made.
- [ ] Add or refine runtime metadata for supported agentic models when fallback metadata causes avoidable mistakes.
- [ ] Continue deprecating non-agentic models in product surfaces without breaking compatibility use cases.

## Telemetry And Analysis
- [ ] Add telemetry that makes “tool-only turn”, “post-edit loop”, and “forced finalize” decisions obvious in one glance.
- [ ] Keep `trace/telemetry.py` ahead of current debugging needs instead of letting raw logs accumulate faster than we can inspect them.
- [ ] Build better comparative evidence for model quirks across providers rather than treating one broken run as universal truth.

## Model Research
- [ ] Refresh the supported-model evidence set periodically from Artificial Analysis and the LiteLLM gateway inventory.
- [ ] Keep validating which models are actually agentic in Codex-style tasks, not just in benchmark marketing.
- [ ] Document backend-specific quirks only after reproducing them.

## Packaging And Distribution
- [ ] Keep npm/GitHub release automation aligned with the real patch baseline.
- [ ] Decide which non-desktop packaging targets are worth keeping in the critical path and which should remain best-effort.
- [ ] Fix update-check behavior so published builds do not point users back to upstream package metadata.
