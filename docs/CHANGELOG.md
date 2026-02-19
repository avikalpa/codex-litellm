# Changelog

All notable changes after `rust-v.0.0.2504292236` will be documented here.
Use VS Code-style headings:

## Highlights
- Rebased our LiteLLM patchset onto upstream `rust-v0.104.0` so we stay current with the latest Codex app-server interface and CLI/TUI behavior.
- Context left meter now uses our own tokenizer estimate and triggers inline auto-compaction before LiteLLM requests blow past the window.
- OSS status cards once again show the signed-in account info thanks to the new AuthManager plumbing, and the rate-limit switch prompt respects/persists the user’s choice.
- Added a dedicated TUI telemetry log (`codex-tui-stream.jsonl`) plus a helper CLI so every reasoning chunk and history line can be replayed without copy/paste.
- Added agentic-first model curation workflow and documentation, including interactive Artificial Analysis benchmark verification before updating supported-model policy.

## Detailed Changes
- repo: update `stable-tag.patch` against upstream tag `rust-v0.104.0` and ensure every LiteLLM crate/config tweak applies cleanly on the new base.
- core: add `context_usage_estimate` bookkeeping plus a tokenizer-based prompt estimator so the CLI/TUI show realistic context percentages and LiteLLM auto-compaction runs before each turn when needed.
- tui/exec: consume the new `TokenCountEvent.context_usage_estimate` channel so `/status`, the header meter, and human-output mode all continue to show total token spend while using the local prompt estimate for the context gauge.
- app-server: re-sync `codex_message_processor.rs` with 0.104 (new model list + feedback upload APIs, richer conversation summaries, updated rate-limit notifications).
- tui: reintroduce `should_exit` handling in onboarding, rewire `/status` to accept the auth manager so ChatGPT account info renders, and add AppEvents + config writes so the rate-limit switch prompt can be dismissed permanently.
- telemetry: new `codex-litellm-debug-tui-telemetry` crate captures reasoning deltas and rendered history lines, exposes a `[telemetry.logs."tui-view"]` config knob, and extends `trace/telemetry.py` with a `tui` sub-command to inspect the new JSONL stream.
- models/docs: add supported-model inventory and enforce an agentic-first maintenance loop backed by interactive Chromium checks on Artificial Analysis benchmark pages and LiteLLM `/v1/responses` capability audits.
