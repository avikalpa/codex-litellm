# codex-litellm

Patched build of the OpenAI Codex CLI that talks directly to a LiteLLM API without a proxy.  The patchset is published as `stable-tag.patch`, letting anyone rebase onto new upstream releases while keeping the stock `codex` binary untouched.

## Quick start

```bash
# install via npm (requires Node 18+)
npm install -g @avikalpa/codex-litellm

# run the CLI
test-codex() {
  CODEX_HOME="${HOME}/.codex-litellm" \
  codex-litellm exec "hello"
}
```

The installer downloads a prebuilt binary for your platform (Linux x64/arm64, macOS x64/arm64, Windows x64/arm64, FreeBSD x64, and Android arm64).  If no prebuilt is available the installer aborts and you can fall back to a local build.

## Local builds

The repository keeps upstream sources out of tree; `build.sh` clones `openai/codex`, checks out the latest stable `rust-v*` tag, applies `stable-tag.patch`, and compiles the workspace.

```bash
# native linux build (x86_64)
./build.sh

# cross-compile for android/termux (requires `cargo install cross`)
USE_CROSS=1 TARGET=aarch64-linux-android ./build.sh
```

Outputs land in `dist/` as tarballs plus SHA256 checksums (`codex-litellm-<platform>.tar.gz`).  The same script is used by CI, so if you need to debug an automation failure you are looking at the exact same steps.

### Development tips

1. Export `CODEX_HOME=$(pwd)/sandbox/.codex` before launching `codex-litellm` so you never touch your real `~/.codex` directory.
2. `setup-test-env.sh` provisions a sample workspace that mirrors our CI smoke tests.
3. `stable-tag.patch` is regenerated with `git diff <upstream-tag>` inside the `codex/` checkout.  Keep that file as the single source of truth for modifications.

More notes on day-to-day work live in [`docs/PROJECT_SUMMARY.md`](docs/PROJECT_SUMMARY.md) and the open roadmap lives in [`docs/TODOS.md`](docs/TODOS.md).

## Release automation

GitHub Actions (`.github/workflows/build.yml`) builds on every push and pull request, generating:

- `codex-litellm-linux-x64.tar.gz`
- `codex-litellm-android-arm64.tar.gz`

When a GitHub release is created the workflow re-runs, attaches artifacts, and publishes the npm package (requires `NPM_TOKEN`).

## Repository layout

```
├── build.sh                 # reproducible patch + build pipeline
├── stable-tag.patch         # patchset applied on top of upstream `codex`
├── docs/                    # project summary and task list
├── scripts/                 # npm installer (downloads release artifacts)
├── bin/                     # launcher shim that finds the correct binary
├── dist/                    # generated binaries (gitignored)
└── config.toml              # sample LiteLLM configuration copied into CODEX_HOME
```

## Contributing

Issues and patches are welcome.  Use `docs/TODOS.md` to see the current priorities; if you pick something up, open an issue or PR so we can coordinate.  Releases follow the upstream tag and carry the short commit hash (e.g. `v0.50.0+cd6y5t`).
