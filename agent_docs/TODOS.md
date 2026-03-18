# TODOs

## Release-Critical
- [ ] Regenerate `stable-tag.patch` from the final `0.115.0` state before the release commit.

## Model Runtime
- [ ] Keep tightening post-edit finalization so agentic models stop exploring once the requested change is made.
- [ ] Keep runtime metadata for supported agentic models aligned so they do not silently fall back again.
- [ ] Add explicit metadata for `vercel/bon-gour/kimi-k2.5` and `vercel/bon-gour/deepseek-v3.2-thinking`.
- [ ] Fix the DeepSeek `reasoning_content` failure on LiteLLM/Vercel tool-use turns.
- [ ] Continue deprecating non-agentic models in product surfaces without breaking compatibility use cases.

## Telemetry And Analysis
- [ ] Add telemetry that makes “tool-only turn”, “post-edit loop”, and “forced finalize” decisions obvious in one glance.
- [ ] Keep `trace/telemetry.py` ahead of current debugging needs instead of letting raw logs accumulate faster than we can inspect them.
- [ ] Build better comparative evidence for model quirks across providers rather than treating one broken run as universal truth.

## Model Research
- [ ] Refresh the supported-model evidence set periodically from Artificial Analysis and the LiteLLM gateway inventory.
- [ ] Keep validating which models are actually agentic in Codex-style tasks, not just in benchmark marketing.
- [ ] Keep the fixture matrix (`mini-web`, `python-cli`, heavier real repos) healthy so testing is not bottlenecked on `calibre-web`.
- [ ] Document backend-specific quirks only after reproducing them.

## Packaging And Distribution
- [ ] Keep npm/GitHub release automation aligned with the real patch baseline.
- [ ] Decide which non-desktop packaging targets are worth keeping in the critical path and which should remain best-effort.
- [ ] Fix update-check behavior so published builds do not point users back to upstream package metadata.
