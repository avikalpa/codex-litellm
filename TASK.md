# Active Task

Refresh `codex-litellm` to upstream `rust-v0.132.0`, keep the patchset minimal, and publish only after release gates pass.

Current constraints:
- `/responses` is the supported LiteLLM API path.
- `/chat/completions` is deprecated.
- UI changes are limited to first-run LiteLLM setup and the LiteLLM `/model` selector.
- Custom context-management policy should not be carried forward.
- Operator documentation lives in `docs/*.md`.

See `docs/CURRENT_TASK.md` for current validation state.
