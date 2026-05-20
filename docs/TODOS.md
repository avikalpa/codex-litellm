# TODOs

## Release-Critical
- [ ] Finish focused local Rust tests for the v0.132.0 port.
- [ ] Update root npm metadata and lockfile to `0.132.0`.
- [ ] Regenerate `stable-tag.patch` from `rust-v0.132.0`.
- [ ] Run low-cost release smokes.
- [ ] Run the required live LiteLLM model gate before publishing.

## Patch Hygiene
- [x] Move operator docs into top-level `docs/*.md` files.
- [x] Deprecate `/chat/completions` in docs and keep examples on `/responses`.
- [x] Remove project-specific context-management policy from the patch direction.
- [ ] Recheck `stable-tag.patch` for stale context-manager, branding, or chat-completions code before commit.

## Model Runtime
- [ ] Keep the `/model` selector based on gateway-discovered models instead of a static LiteLLM allowlist.
- [ ] Continue documenting route-specific model behavior only after live Codex-harness evidence.

## Packaging And Distribution
- [ ] Push `main` only after metadata, patch, and local gates agree.
- [ ] Create the GitHub release and verify release assets.
- [ ] Verify npm publish and `npm view @avikalpa/codex-litellm version`.
