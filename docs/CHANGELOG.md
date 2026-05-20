# Changelog

This file tracks user-visible changes in `codex-litellm`.

## Unreleased
`codex-litellm` is refreshed onto upstream `rust-v0.132.0`. This release keeps the patchset narrower: `/responses` is the LiteLLM path, `/chat/completions` is deprecated, model discovery comes from the LiteLLM `/v1/models` endpoint, and custom context-management policy has been removed in favor of upstream Codex defaults.

### Highlights
- Refreshed the maintained patchset onto upstream `rust-v0.132.0`.
- Kept LiteLLM on the `/responses` API path and documented `/chat/completions` as deprecated.
- Added a simple `codex-litellm` first-run setup flow for base URL, API key, and optional default model.
- Kept the UI delta limited to first-run setup and the LiteLLM-aware `/model` selector.
- Updated LiteLLM `/model` discovery so OpenAI-compatible `/v1/models` responses can populate the catalog.
- Removed project-specific context-management code and model context metadata patches.
- Moved operator documentation into top-level `docs/*.md` files.

### Detailed Changes
- upstream: rebased the maintained LiteLLM patchset onto `rust-v0.132.0` and aligned the nested checkout to `13595c36e218fcbd13df118eeadf00d4eb0e6d31`.
- runtime: added a built-in `litellm` provider using `wire_api = "responses"`, `LITELLM_BASE_URL`, and `LITELLM_API_KEY`.
- runtime: preserved LiteLLM tool-schema normalization for providers that reject upstream Responses tool shapes.
- runtime: retries a LiteLLM Responses request once without `reasoning` when the gateway rejects `reasoning_effort`.
- models: accepts OpenAI-compatible `/v1/models` payloads and treats returned slugs as selectable compatibility entries.
- models: avoids seeding the LiteLLM picker from OpenAI's bundled model catalog, so the picker reflects gateway discovery instead of a static allowlist.
- models: refreshed the release-gate MiniMax route to the gateway-canonical `vercel/maa/minimax-m2.7-highspeed` slug.
- sessions: keeps normal upstream provider filtering, while allowing the LiteLLM profile to see shared local sessions under `~/.codex`.
- docs: updated README, release guidance, behavior notes, and interface notes for the docs move and Responses-only direction.

## Format
Use a release-story format:
- short intro paragraph that explains what this release means for users
- `Highlights` for the high-signal changes
- `Detailed Changes` for concrete technical detail
- keep the narrative user-facing first and maintainer-precise second
- if `README.md` changes materially, make sure the changelog and README tell the same story
