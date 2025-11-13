# `codex-litellm` Project Log & Context

**Project:** `codex-litellm`
**Objective:** To create and maintain a set of patches for the `codex-cli` source code. The primary goal of these patches is to enable direct, reliable communication between the `codex-cli` and a `litellm`-based backend, eliminating the need for an external proxy and fixing critical underlying bugs.
**Patch Philosophy:** Inspired by GrapheneOS's Android patchsets, this repo curates reproducible diffs against `openai/codex` so litellm support can be layered on top of the upstream sources without forking.
**Binary Rename:** The patched build ships as `codex-litellm` so it can be installed alongside the upstream `codex` binary.
**Dual CLI Goal:** Keep the stock `codex` CLI available while shipping the patched `codex-litellm` binary built from these patches.

---

## 1. The Core Problem & History

This project was born out of a persistent and complex issue: making the `codex-cli` work with a custom `litellm` endpoint.

### Phase 1: Direct Connection (Initially Failed, Now Patched)
- **Initial Attempt:** The `~/.codex/config.toml` was configured to point directly to the `litellm` endpoint. While the `config.toml` settings are now correct, this initially resulted in the `codex exec` command hanging because the backend's streaming response was incompatible with the client.
- **Solution Evolution:** The patch file `stable-tag.patch` contains the comprehensive set of modifications. Previously the history was documented in a series of numbered patch files (`0000-*.patch`, `0001-*.patch`, etc.), but these have been consolidated into a single file for clarity and ease of use. `stable-tag.patch` is always generated against the latest upstream stable tag we track (currently `rust-v0.50.0`).

### Phase 2: The Proxy Workaround (Failure)
- **Strategy:** To bridge the incompatibility, a proxy server was developed. The proxy's job was to receive the request from `codex-cli`, make a **non-streaming** request to `litellm` to get a complete response, and then **simulate** a valid SSE stream back to the client.
- **Implementations:** This was attempted with both a Python/Flask server and a Rust/Warp server.
- **Result:** A catastrophic, low-level bug was discovered. Any server process that accepted a connection from `codex-cli` would **instantly crash**.
- **Conclusion:** The proxy approach was therefore abandoned.

### Phase 3: The `codex-patches` Initiative (Current Strategy)
- **Strategy:** Since the bug is in the client, we will fix the client directly. Instead of an external proxy, we will port the successful "fetch-and-simulate" logic *inside* the `codex-cli`'s Rust codebase.
- **Benefits:** This approach is more robust, eliminates a point of failure (the proxy), and directly addresses both the `litellm` streaming incompatibility and the client-side network bug.
- **Workflow:** We will maintain our modifications as patch files in this repository, allowing us to re-apply them to future upstream versions of `codex-cli`.

---

## 2. Key Directories & Files

- **`codex/`**: A clone of the official `codex` source code repository. This is where the code modifications will be made.
- **Repository root** (`~/gh/codex-litellm/`): Headquarters for our patchset project.
    - **`AGENTS.md`**: Project operating manual (this document). `CLAUDE.md` remains for historical reference only.
- **`docs/`**: Contains detailed strategic and analytical documents. The primary roadmap for any implementation task will be located here (`docs/TODOS.md`, `docs/PROJECT_SUMMARY.md`, etc.).
- **`docs/CURRENT_TASK.md`**: The live hand-off note for the active debugging task. Read it at the start of every session and update it before handing off again.
- **`docs/MODEL_BEHAVIOR.md`**: Tracks how our LiteLLM integration diverges from upstream Codex (buffered OSS fallback rules, reasoning styling, exec vs TUI expectations). Update it whenever you change the request/response pipeline.
- **Manual model probes:** When a non-agentic model misbehaves, reproduce it outside Codex before patching. First call the LiteLLM endpoint via `curl …/chat/completions` to inspect the raw `tool_calls`. If the model stalls after a tool, use the Python harness (see `MODEL_BEHAVIOR.md`) to execute the commands and resend tool outputs—log the findings in `docs/CURRENT_TASK.md`.
- **Observability first:** When behavior is unclear, add telemetry before attempting a fix. Instrument both the core (request/response) and the TUI so we can see what the model sent, what we forwarded, and how the UI rendered it. Never assume; capture the evidence in logs and reference it in `docs/CURRENT_TASK.md`. Use `python trace/telemetry.py …` to slice the JSONL sessions (`list`, `events`, `summary`) instead of scrolling giant logs by hand. Set `CODEX_TRACE_HOME` if you need to inspect an alternate `CODEX_HOME`. If the helper ever needs third-party deps, create `trace/venv` with `uv venv trace/venv` (preferred) or a standard virtualenv; the path is already gitignored. Legacy helpers under `scripts/` are considered deprecated—migrate any remaining use cases to the new tracing tool before touching them. Treat `trace/telemetry.py` as a living tool: whenever a new debugging scenario needs richer probes, extend the tracer first so future sweeps inherit the observability upgrade automatically.
- **Release notes:** Keep `docs/CHANGELOG.md` up to date in VS Code–style format (Highlights + Detailed Changes). This file seeds the GitHub release notes, so update it after every notable change affecting end users.
- **`stable-tag.patch`**: Diff generated from the `codex/` source tree after modifications are complete.
- **`config.toml`**: Canonical LiteLLM configuration. Copy this into the active CODEX_HOME during testing so runs target the correct backend. (The repo copy is intentionally blank; pull from `~/.codex-litellm-debug/config.toml` whenever you need a seeded profile.)
- **`docs/TELEMETRY.md`**: Reference for the LiteLLM-only debug and session telemetry modules.
- **`docs/COMPLIANCE.md`**: Licensing and attribution rules (Apache-2.0 baseline, NOTICE policy, source header guidance).
- **`docs/PUBLISHING.md`**: Release checklist covering tag naming, build validation, npm publish, and post-release verification steps. When drafting release notes, follow a VS Code-style changelog: start with a short intro paragraph followed by concise bullet highlights that compile the changes since the previous build.

---

## 3. Collaboration Workflow

Codex (this agent) is the primary engineer for day-to-day work. Gemini may occasionally provide strategy or planning support when requested.

-   **Codex:** Leads implementation, integration, and patch maintenance.
-   **Gemini (on demand):** Contributes strategic analysis or planning support when explicitly invited.

This structured approach ensures that our work is methodical, well-documented, and ultimately successful.

### Daily Operator Loop

1. Begin every work session by skimming `TASK.md` for the current sweep notes and journaling context. Add a new entry if you start a fresh sweep.
2. Review `docs/TODOS.md` and pick the next actionable item. Feel free to append TODOs as new issues are discovered.
3. Tackle tasks one milestone at a time. After each milestone (bug fix, feature slice, doc update), regenerate `stable-tag.patch`, then commit the root repository per the steps in `docs/COMMITTING_NOTES.md`.
4. When telemetry, onboarding, or other sensitive flows change, record the behaviour in `docs/TELEMETRY.md` and update `docs/PROJECT_SUMMARY.md` as needed.
5. Always run `cargo build --locked --bin codex` before handing the tree back to the user. Prefer adding focused tests (`cargo test -p codex-tui`, `cargo insta test`) when they cover the regression you are fixing.
6. Before asking the user to run the TUI, smoke-test the change with `timeout 90s CODEX_HOME=/tmp/codex-home-oss-test ../codex/codex-rs/target/debug/codex exec "<prompt>" --model vercel/gpt-oss-20b --skip-git-repo-check`. Only request TUI validation after the exec run produces a final assistant reply plus token usage.

---

## 4. Patching and Testing Workflow

Due to the nature of this project, where we are patching an upstream repository, we need a robust workflow for testing our changes.

**WARNING:** The `build.sh` script is designed for automated release builds. It will destroy any manual changes in the `codex/` directory by running `git reset --hard`. Do NOT use it during development.

**Environment Isolation:** The canonical testing home is `CODEX_HOME=/root/.codex-litellm-debug`. That directory already contains the blessed `config.toml` pointing at `https://llm.gour.top/chat/completions` and the current model defaults (`vercel/gpt-oss-120b`, medium reasoning). When you edit the repo’s `config.toml`, immediately copy it into `~/.codex-litellm-debug/` so both stay in lock-step. If a sandbox blocks writes to that path, fall back to a workspace-local directory (e.g. `test-workspace/.codex`) only for that run and sync the debug profile afterward. Never point the sandbox at `https://api.openai.com/...`; all validation must target the LiteLLM gateway above.

### Debug build + test-workspace loop

1. `cd codex/codex-rs && cargo build --locked --bin codex` (always exercise the debug build; it enables our telemetry crates).
2. Recreate the Calibre-Web workspace: `rm -rf test-workspace && ./setup-test-env.sh`. Re-cloning before every sweep keeps diffs deterministic.
3. `cd test-workspace` and run every manual scenario with the debug binary:  
   `CODEX_HOME=/root/.codex-litellm-debug ../codex/codex-rs/target/debug/codex exec "<prompt>" --model <slug> --skip-git-repo-check`
4. Keep `/root/.codex-litellm-debug/sessions/` and `logs/` intact—those captures prove regressions. If the config changes (model slug, endpoint, telemetry), update both the repo root and the debug home in the same commit.
5. Upstream `codex` is for A/B comparisons only. All functional testing, `/status` checks, and telemetry captures must use the patched debug binary.

### Mandatory model behaviour tests

Before every GitHub push or release, run the manual scenarios in `docs/MODEL_BEHAVIOR_TESTS.md` **in order**: non-agentic (`vercel/gpt-oss-120b`) first, then agentic (`vercel/minimax-m2`). Both runs use the gradient/pill prompt that ends with “Just do it. Do not ask for permission.” Each model must finish the job without disconnecting or requiring manual “continue” nudges; capture the logs under `logs/` if anything deviates and block the release until fixed.

- **Stdout nuance:** `codex exec` writes assistant messages to both the streaming renderer and a final stdout flush. When viewed live this looks like a duplicated response, but redirecting stdout to a file (e.g. `codex exec "who are you?" > reply.txt`) shows only a single copy. Treat the double print in interactive runs as expected behavior, not a regression.

1.  **Manual Build and Patch:** Instead of relying on `build.sh` for development, we will perform manual builds based on the latest stable release tag. This involves:
    *   Fetching the latest tags from the upstream `codex` repository: `git fetch --tags`.
    *   Finding the latest stable tag (e.g., `git tag | grep "^rust-v" | grep -v "alpha\|beta" | sed 's/^rust-v//' | sed 's/^\.//' | sort -V | tail -n 1`). Avoid any tags marked with `alpha`, `beta`, or other pre-release identifiers.
    *   Checking out that tag: `git checkout <latest-stable-tag>`.
    *   Applying our existing patch with `git apply ../<patch-file-name>.patch`.
    *   Manually applying any additional fixes to the codebase.
    *   Building the CLI in debug mode with `cargo build` in the `codex/codex-rs` workspace.
    *   If `git apply` fails or the UI suddenly reverts to upstream defaults, pause and walk through the recovery checklist in `docs/COMMITTING_NOTES.md#when-the-patch-no-longer-applies` before continuing.

2.  **Testing:**
    *   Recreate the Calibre-Web repo each sweep: `rm -rf test-workspace && ./setup-test-env.sh`.
    *   `cd test-workspace`.
    *   Run the debug binary straight from the build tree with the canonical profile:  
        `CODEX_HOME=/root/.codex-litellm-debug ../codex/codex-rs/target/debug/codex exec "<prompt>" --model <slug> --skip-git-repo-check`
    *   Run simple commands like `../codex/codex-rs/target/debug/codex "2+2"` (or invoke the symlinked `codex-litellm`) to test basic functionality.
    *   Run complex commands like `../codex/codex-rs/target/debug/codex "List the files in the repo and make a context in AGENTS.md" --skip-git-repo-check` to test tool-calling.

3.  **Creating a New Patchset:**
    *   Once the changes are verified, we will create a new, unified patch file.
    *   This involves creating a new branch, committing the changes, and then using `git format-patch` to create the new patch file.
    *   **Before handing off any change for testing, always run `cargo build --bin codex` as the final step.**

---

## 5. Debugging Workflow

When a new bug report is filed in the `docs/` directory, the following workflow must be followed:

1.  **Reset Repository:** Start from a clean state by running `git reset --hard HEAD` within the `codex/` directory.
2.  **Apply Final Patch:** Apply the latest stable patch with `git apply ../stable-tag.patch`.
3.  **Build & Test:** Build a debug version of the CLI using `cargo build` in `codex/codex-rs`. Then, test the reported issue to confirm if the current patch resolves it.
4.  **Iterate and Debug:**
    *   If the bug persists, investigate the `codex` and `litellm` source code to develop a fix.
    *   Use `docs/PROJECT_SUMMARY.md` as a scratchpad to document findings, hypotheses, and debugging steps.
    *   After applying a potential fix, rebuild and re-test.
5.  **Create New Patch:**
    *   Once the bug is resolved, regenerate `stable-tag.patch` against the latest upstream release tag (overwriting the previous file).
    *   **CRITICAL:** After any code changes in the `codex/` directory, regenerate `stable-tag.patch` before committing to the `codex-litellm` repository.
6.  **Final Verification:** Reset the repository again, apply `stable-tag.patch`, build, and run the test for the latest user report to ensure the fix is correctly captured and works on a clean checkout.

---

## 7. Debugging Learnings & Stumbles

This section documents incorrect assumptions and procedural errors made during debugging to prevent them from happening again.

-   **Forgetting to Regenerate Patches:** A critical error was made where fixes were applied to the `codex/` codebase, but a new patch file was not generated before committing to `codex-litellm`. This rendered the baseline commit useless. **Lesson:** Always run `git format-patch` to create a new patch after *any* modification in the `codex/` directory.
-   **Incorrect Log File Assumptions:**
    1.  Assumed logs would be in `/tmp/codex-*.log`. They were not.
    2.  Assumed `codex exec` would write to the TUI log at `~/.codex/log/codex-tui.log`. It does not, as it's a separate process.
    3.  Attempted to write logs to `/tmp/`, forgetting that the tool environment has restricted filesystem access.
    4.  Forgot that `info!` and `debug!` macros require the `RUST_LOG` environment variable to be set to the appropriate level (e.g., `RUST_LOG=info`) to be captured in stderr.
-   **Lesson:** When debugging `codex exec`, the most reliable way to capture logs is to redirect `stderr` to a file within the current working directory (e.g., `test-workspace/`) and ensure `RUST_LOG` is set appropriately. For example: `RUST_LOG=info ../codex/codex-rs/target/debug/codex exec "..." 2> exec.log`.
-   **False Positive and Flawed Analysis:** I incorrectly concluded that the `apply_patch` tool was working based on the agent's internal monologue, without verifying the actual outcome. A simple `git status` check, as you correctly pointed out, would have immediately revealed that no files were changed. This was a major oversight.
-   **Root Cause Misdiagnosis:** My focus on the race condition, while a real but secondary issue, blinded me to the more fundamental problem: the "fetch-and-simulate" logic was incomplete. It was only simulating the *request* for a tool call, not the entire loop of execution and response.
-   **Lesson:** Do not assume success based on agent logs alone. **Always verify the actual side-effects** of any operation (e.g., file changes, process status). The `git status` command is an invaluable tool for this. Furthermore, when a fix seems too simple, it's a sign to dig deeper and question the initial diagnosis.
-   **Build Performance:** Rust build times, especially for large projects, can be slow. `cargo` uses incremental compilation by default, which helps for small changes. For significant speed-ups, a more powerful machine or distributed compilation tools like `sccache` would be necessary. For our purposes, we will proceed with the existing build times.
-   **Configuration File Location:** The `codex-cli` looks for `config.toml` under `CODEX_HOME` (falling back to `~/.codex` when unset). During development we point `CODEX_HOME` at the workspace-local `.codex` directory and copy the repo’s `config.toml` there so tests never mutate the user’s real configuration.
-   **Patching Workflow:** When a fix is verified, regenerate `stable-tag.patch` against the current upstream release tag (e.g., `rust-v0.50.0`). This file overwrites the previous patch and is always applied from the `codex/` directory via `git apply ../stable-tag.patch`.
-   **Milestone Commits:** After each significant checkpoint—especially right after regenerating `stable-tag.patch`—capture the state via the workflow documented in `docs/COMMITTING_NOTES.md` so upstream history stays clean and our patch log remains reproducible.
- **Assumptions are the enemy of progress:** I have made the mistake of assuming the cause of an issue without first verifying it by consulting the source of truth (e.g., source code, documentation, or direct API calls). This has led to wasted time and effort. **Lesson:** Always check the source of truth before implementing a fix.
- **Manual Edits:** If I am unable to edit a file, I will create a `manual-edit.txt` file in the `codex-litellm/` directory with the code that needs to be manually edited. I will then ask you to perform the manual edit and will verify the changes before proceeding.

---
## Telemetry Modules

See `docs/EXCLUSIVE_FEATURES.md` for configuration knobs and logging formats.

- `codex-litellm-debug-telemetry`: tracing hooks and log writers that capture high-fidelity debug events (header layout, onboarding flow, etc.) into timestamped files under `logs/` for post-mortem analysis.
- `codex-litellm-model-session-telemetry`: in-memory aggregation of LiteLLM model usage (tokens and turn counts) surfaced via `/status` to mirror upstream Codex billing insights.

Runtime toggles: pass `--telemetry` or `--no-telemetry` to `codex` / `codex exec` when you need to override the `[telemetry] enabled` setting without editing `config.toml`.

---
## 8. Generating a Unified Patch File

### Purpose

The primary goal is to consolidate all our modifications to the `codex/` source tree into a single, unified patch file. This file represents the difference between a known stable baseline (a specific git tag, e.g., `rust-v0.47.0`) and our current working directory. This allows us or other developers to easily re-apply our specific set of changes to a clean, stable version of the upstream `codex` repository.

### How to Generate the Patch

1.  **Navigate to the `codex` directory:** All `git` commands must be run from within the `codex/` subdirectory.
2.  **Identify the Baseline Commit:** Determine the commit hash of the stable tag you are diffing against. For example, for version `v0.0.50`, this is `b4123b7b1db22a3c0a8b133a23c7b30a477d7b65`.
3.  **Generate the Diff:** Use the `git diff` command to compare the baseline commit against the current state of the working directory.

    ```bash
    # From within the codex/ directory
    git diff <baseline-commit-hash> > ../stable-tag.patch
    ```
    *Replace `<baseline-commit-hash>` with the actual commit hash for the stable tag.*

### CRITICAL: How to Avoid Generating an Empty Patch

A critical mistake was made previously by using the command `git diff <commit> HEAD`. This is **incorrect** and will produce an empty file if your `HEAD` is currently pointing to that exact same commit (which it is after checking out a tag).

-   **Correct:** `git diff <commit-hash>`
    -   This compares the specified commit with the **current working directory**, capturing all uncommitted changes.

-   **Incorrect:** `git diff <commit-hash> HEAD`
    -   This compares the specified commit with where `HEAD` is pointing. If they are the same, the diff is empty.

---
## 9. Operational Protocol

- **Do Not Modify Documentation During Debugging:** When a logic is not working or a solution is not yet found, do not modify any `.md` files, including this one (`AGENTS.md`), without explicit instructions from the user. This includes adding escalation notes or summaries of failed attempts.
