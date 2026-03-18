# Publishing

This is the release checklist for `codex-litellm`. If any step fails, stop and fix the release inputs before retrying.

## Release Preconditions
- `main` already contains the intended upstream refresh.
- `codex/`, `stable-tag.patch`, `package.json`, and `package-lock.json` all point at the same upstream base.
- The release is validated on the LiteLLM `/responses` path. That is the default path forward for `codex-litellm`.
- The required live model checks in `agent_docs/MODEL_BEHAVIOR_TESTS.md` pass.
- `agent_docs/CHANGELOG.md` is updated for the release.
- The release will be built on GitHub Actions. Local release artifacts are not the publish source.

## Versioning Rules
- `package.json.version` and `package.json.codexLitellm.baseVersion` track the upstream Codex version.
- `package.json.codexLitellm.upstreamCommit` tracks the exact upstream commit we are patching.
- `package.json.codexLitellm.releaseTag` is the human-facing release seed.
- The published npm version is derived from the GitHub release tag by replacing `+` with `-`.

## Local Release Prep
1. Confirm the pinned upstream base:
   - `node -p "require('./package.json').codexLitellm.baseVersion"`
   - `git -C codex describe --tags --exact-match HEAD`
2. Regenerate `package-lock.json`:
   - `npm install --package-lock-only --ignore-scripts`
3. Run the metadata checks:
   - `./scripts/test-build-sh-metadata.sh`
   - `./scripts/test-npm-release-version.sh`
4. Run the required build/test checks:
   - `cargo build --locked --bin codex`
   - any targeted tests needed for the release
   - required live model smokes from `agent_docs/MODEL_BEHAVIOR_TESTS.md`
5. Make sure the intended user path is not broken:
   - default `~/.codex` config path still works
   - debug-only `CODEX_HOME` behavior has not become a hidden dependency

## Tagging
1. Commit the release-ready state.
2. Ask the user whether to publish now.
3. Push `main`.
4. Create the release tag from the current committed state:
   - `VERSION=$(node -p "require('./package.json').codexLitellm.baseVersion")`
   - `UPSTREAM=$(node -p "require('./package.json').codexLitellm.upstreamCommit")`
   - `LIT=$(git rev-parse --short HEAD)`
   - `TAG="v${VERSION}+${UPSTREAM}+lit${LIT}"`
5. Create the GitHub release for that tag.

## Post-Tag Verification
- Verify the GitHub workflow starts.
- Verify `Release preflight` passes.
- Verify core build jobs succeed.
- Verify release assets attach.
- Verify `publish-npm` succeeds.
- Verify npm output explicitly:
  - `npm view @avikalpa/codex-litellm version`
  - `npm dist-tag ls @avikalpa/codex-litellm`

## Release Gate
Do not call a release complete until npm and GitHub both show the intended version.
