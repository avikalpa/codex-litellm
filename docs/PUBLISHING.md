# Publishing codex-litellm

This note tracks the exact checklist for turning a passing patch into a release that ships
prebuilt binaries and the npm package. Follow every step in order; each depends on the
previous one.

## 1. Prepare the working tree
1. Ensure `stable-tag.patch` applies cleanly to the latest upstream tag (targeting
   `rust-vX.Y.Z`). Update the patch if upstream moved (see `docs/COMMITTING_NOTES.md`).
2. Run local builds for the desktop targets:
   ```bash
   ./build.sh                       # linux-x64
   TARGET=aarch64-unknown-linux-gnu USE_CROSS=1 ./build.sh  # linux-arm64 if cross set up
   ```
   For mac targets, rely on CI cross-builds.
3. Run the smoke test against the LiteLLM backend (requires valid credentials):
   ```bash
   npm install --package-lock-only --ignore-scripts
   CODEX_LITELLM_SKIP_DOWNLOAD=1 npm install -g .
   install -D dist/linux-x64/codex-litellm \
       "$(npm root -g)/@avikalpa/codex-litellm/dist/linux-x64/codex-litellm"
   LITELLM_BASE_URL=https://llm.gour.top \
   LITELLM_API_KEY=<token> \
   codex-litellm --model vercel/gpt-oss-120b exec "who are you"
   ```
   The command should complete with a Codex response. If it fails, fix the bug before
   continuing.

## 2. Version stamping
1. Determine the upstream and patch commits:
   ```bash
   UPSTREAM=$(cd codex && git rev-parse --short HEAD)
   LIT=$(git rev-parse --short HEAD)
   echo "Upstream: $UPSTREAM   Patched: $LIT"
   ```
2. Update `package.json`:
   * Set `version` to the upstream `X.Y.Z`.
   * Update `codexLitellm.baseVersion` and `codexLitellm.upstreamCommit` to the values above.
   * Set `codexLitellm.releaseTag` to `vX.Y.Z-litellm.dev` (the workflow overwrites it during
     `npm publish`). The job also derives an npm-safe version by replacing `+` with `-`
     (exposed as `codexLitellm.npmVersion`) because the registry rejects literal `+` metadata.
   * Regenerate `package-lock.json` with
     `npm install --package-lock-only --ignore-scripts`.
3. Ensure `build.sh` still exports `CODEX_UPSTREAM_COMMIT`/`CODEX_LITELLM_COMMIT`; run
   `./build.sh` once to verify the metadata string looks like
   `X.Y.Z+<upstream>+lit<patched>`.

## 3. Commit and tag
1. Commit all updated files, including `stable-tag.patch`, docs, workflow, and npm metadata.
2. Create the release version string for tagging and npm publish:
   ```bash
   VERSION=$(node -p "require('./package.json').codexLitellm.baseVersion")
   UPSTREAM=$(node -p "require('./package.json').codexLitellm.upstreamCommit")
   LIT=$(git rev-parse --short HEAD)
   RELEASE="${VERSION}+${UPSTREAM}+lit${LIT}"
   TAG="v${RELEASE}"
   ```
3. Push `main`, then create the GitHub release:
   ```bash
   git push origin main
   gh release create "$TAG" --title "codex-litellm $RELEASE" --notes "<highlights>"
   ```
   The publication workflow will start automatically.

## 4. CI and npm verification
1. Wait for workflow `Build and Release` to finish. It should:
   * Build linux/macos artifacts.
   * Attach `.tar.gz` + `.sha256` files to the release.
   * Publish `@avikalpa/codex-litellm@$RELEASE` to npm (see
     `Actions → Build and Release → publish-npm`).

2. Verify outputs:
   ```bash
   gh release view "$TAG" --json assets
   npm view @avikalpa/codex-litellm version
   ```
   The npm version should read the hyphenated variant
   (`${RELEASE//+/-}`) published in step 1.

3. Run the manual install test from a clean environment:
   ```bash
   npm uninstall -g @avikalpa/codex-litellm
   npm install -g @avikalpa/codex-litellm
   LITELLM_BASE_URL=https://llm.gour.top \
   LITELLM_API_KEY=<token> \
   codex-litellm --model vercel/gpt-oss-120b exec "who are you"
   ```

## 5. Follow-up
- Update `docs/TODOS.md` (mark install test complete, plan for OpenWrt/Termux if queued).
- Announce the release (internal channel, blog, etc.).
- Queue the “phase 2” release once OpenWrt/Termux packaging is ready (re-enable the
  workflow jobs before tagging).

Keep this document current: every release should either follow these steps or update them
when the process changes.
