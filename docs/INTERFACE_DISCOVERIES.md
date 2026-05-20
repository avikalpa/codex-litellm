# Interface Discoveries

## Current UI Boundary
The maintained UI delta is intentionally small:
- `codex-litellm` first-run setup for LiteLLM base URL, API key, and optional default model
- the LiteLLM-aware `/model` selector

Everything else should remain upstream Codex UI unless LiteLLM compatibility requires a narrow, documented change.

## First-Run Setup
- The normal path uses `~/.codex`, not a debug-only `CODEX_HOME`.
- First run writes the `codex-litellm` profile, the built-in `litellm` provider, and `.env` secrets.
- The provider must use `wire_api = "responses"`.
- If the user leaves the model blank, the app should start cleanly and let `/model` pick from the LiteLLM catalog.

## `/model` Selector
- For LiteLLM, `/model` should show models discovered from the configured `/v1/models` endpoint.
- The selector may show simple warning rows for missing base URL, missing API key, or an empty catalog.
- The selector must not replace the upstream picker for OpenAI, Ollama, LM Studio, or other providers.
- Namespaced slugs such as `provider/group/model` should remain selectable without requiring hard-coded metadata.

## Deprecated Interface
- `/chat/completions` is deprecated for this project.
- `wire_api = "chat"` is no longer a supported provider config.
- New docs, tests, and examples should use `/responses`.

## Things We Removed
- Custom context-management policy on top of upstream Codex defaults.
- UI branding/header/status changes outside the setup and model-selection path.
- Static LiteLLM model allowlists as the source of truth for the picker.
