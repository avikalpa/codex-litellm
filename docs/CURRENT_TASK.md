# Current Task — OSS Auto-Followups & Minimax UI Regression

Last updated: 2026-03-17

## 2026-03-17 upstream-aa-refresh sweep
- **Worktree:** `/home/pi/gh/codex-litellm-upstream-aa-refresh-20260317` on branch `upstream-aa-refresh-20260317`.
- **Upstream refresh:** `codex/` now targets `rust-v0.115.0` (`f028679a`), `package.json`/`package-lock.json` are bumped to `0.115.0`, and `stable-tag.patch` was regenerated against the new tag.
- **AA + endpoint evidence:** Added `scripts/artificialanalysis-harness.cjs`, refreshed `logs/artificialanalysis-model-slugs.json`, `logs/aa-agentic-click-report.json`, and captured the live LiteLLM inventory in `logs/litellm-models.json`.
- **Agentic allowlist refresh:** The allowlist now tracks current AA + gateway overlap: `gpt-5.4`, `gpt-5.4-pro`, `gpt-5.3-codex`, `claude-sonnet-4.6`, `claude-opus-4.6`, `gemini-3.1-pro-preview`, `gemini-3-pro`, `gemini-3-flash`, `grok-4.1-fast-reasoning`, `deepseek-v3.2-thinking`, `kimi-k2.5`, `minimax-m2.5`.
- **Config regression fixed:** `core/src/config/mod.rs` now lets `config.toml` providers override built-ins, restoring `[model_providers.litellm]` with `experimental_bearer_token` instead of forcing `LITELLM_API_KEY`.
- **Important gateway slug change:** The canonical endpoint no longer accepts shorthand IDs like `vercel/gpt-oss-120b` or `vercel/minimax-m2`; current working IDs are `vercel/bon-gour/gpt-oss-120b`, `vercel/bon-gour/gpt-oss-20b`, and `vercel/bon-gour/minimax-m2.5`.
- **Release blocker:** The live smoke suite is still failing on the refreshed upstream base. Non-agentic `vercel/bon-gour/gpt-oss-120b` exits `0` after a reconnaissance tool call with no final assistant message and no edits (`logs/model-test-vercel_bon-gour_gpt-oss-120b-retry-20260317.log`). Agentic `vercel/bon-gour/minimax-m2.5` makes edits but eventually fails with `400 invalid params, duplicate tool_call id ...` after a reconnect (`logs/model-test-vercel_bon-gour_minimax-m2.5-retry-20260317.log`).
- **Likely root cause:** Current `main` only carries the trimmed provider/allowlist patchset. Older commits such as `d281716` still contain the larger LiteLLM runtime patch (`fetch_chat_completions_buffered`, fallback synthesis, `TaskComplete` fixes, final separator handling). Re-port that patchset onto `rust-v0.115.0` before publishing.

## TL;DR
- **Rebase complete:** `codex/` now tracks upstream `rust-v0.58.0`, the LiteLLM crates are restored, and `cargo build --locked --bin codex` passes on the new base (pending the usual `model_migration.rs` warnings). `stable-tag.patch` is regenerated from this tag.
- **Telemetry upgrade:** Every reasoning delta and rendered history line now lands in `${CODEX_HOME}/logs/codex-tui-stream.jsonl`; use `python trace/telemetry.py tui --limit 200` to replay a TUI session without copy/paste.
- **OSS (`vercel/gpt-oss-20b`)** now enforces a hard 45 s timeout per LiteLLM attempt, keeps tools enabled during buffered follow-ups, and retries **five** times before surfacing a ⚠ warning. Each retry emits `Continuing automatically… (retry X/5; reason; waiting up to 45s)` so the TUI shows real progress while the context meter stays stable. The latest exec smoke (`019a78e7-f0c7-7e51-840f-580cd7992d50`, `CODEX_HOME=/tmp/codex-home-oss-test`) returns the correct “No… React” answer plus token stats with zero duplicate reasoning bubbles.
- **Minimax (`vercel/minimax-m2`)** renders the agentic reasoning block but never prints the “Worked for …” separator or the token usage/resume footer when the turn ends. TaskComplete is missing (no assistant output) and the separator currently shows up *after* the final answer instead of replacing the divider before the assistant reply.
- **Context meter & compaction** now rely on a local tokenizer estimate built from the exact Chat Completions payload before we hit LiteLLM. The estimate feeds a new `context_usage_estimate` channel in `TokenCountEvent`, lets the TUI show a realistic “% left” value, and triggers inline auto-compaction *before* we blow past the LiteLLM window. We still keep the backend-reported totals for `/status` billing lines.
- Legacy telemetry under `~/.codex-litellm-debug/` has now been cleared. Continue using this canonical path (or clone it) so OSS/minimax runs always start with empty `logs/` + `sessions/`.

## Active Worktrees
| Worktree | Path | Branch | Owner | Focus | Notes |
| --- | --- | --- | --- | --- | --- |
| oss-buffered-retries | `../codex-litellm-oss-buffered-retries` | `oss-buffered-retries` | Codex | OSS auto-followup pacing, warning copy, and context meter telemetry | Create/resume via `./scripts/worktree-new oss-buffered-retries main` before following the “OSS Auto-Followup Regression” steps below. Capture rollout IDs in this section after each test. |
| minimax-footer | `../codex-litellm-minimax-footer` | `minimax-footer` | Codex | Minimax “Worked for …” separator and token footer regression | Work exclusively in this tree when touching the minimax tasks, then log the latest session IDs here prior to hand-off. |

## Environment Reset Plan
1. Pick a unique path, e.g. `export CODEX_HOME=/root/.codex-litellm-debug-fresh`.
2. Create it before running tests:
   ```bash
   mkdir -p "$CODEX_HOME"
   # always copy from the canonical LiteLLM profile, the repo copy is empty
   cp /root/.codex-litellm-debug/config.toml "$CODEX_HOME"/
   ```
3. After each test, the new `CODEX_HOME` will contain just the logs for that run (`logs/` + `sessions/`). Zip/tar them if they must be preserved.

> The old `~/.codex-litellm-debug` directory is still there (read-only). Leave it alone; just stop pointing CODEX at it.

## OSS Auto-Followup Regression
- **Command:**
  ```bash
  cd ~/gh/codex-litellm/test-workspace
  CODEX_HOME=$CODEX_HOME RUST_LOG=info ../codex/codex-rs/target/debug/codex exec "Does this project use react?" --model vercel/gpt-oss-20b --skip-git-repo-check
  ```
- **Expected behaviour:** One `ls -R` + one reasoning summary followed by a final assistant answer. No repeated “Pick up from the latest tool output…” prompt.
- **Status (rollouts `019a7d6d-54e4-7e91-b017-87a13032ea5a` exec, `019a7d87-a459-72e3-9423-fccadcac685d` TUI):** Exec still finishes in ~0.5 s and reports a realistic context estimate. TUI now visibly retries up to five times but the pauses between retries are too short (user feedback: retries “flicker”); once the synthetic warning fires the footer reads “Press enter to retry…”.
- **Active bugs (TUI `019a7d87-a459-72e3-9423-fccadcac685d`):**
  1. **Retry pacing** — LiteLLM follow-ups need a longer delay between attempts so “Continuing automatically N/5…” stays onscreen for more than a blink. Update the buffered loop to increase the per-attempt backoff (e.g., 5s/10s/15s/20s/25s) and log the chosen delay via `oss_buffered.retry_delay_ms`.
  2. **Warning copy** — Change the final warning to `⚠ I wasn’t able to finish "<prompt>". LiteLLM stopped replying after 5 automatic retries. Press try again or ask a different question.` (use “Press try again”, no quotes around the button text). Update both exec and TUI renderers.
  3. **Context meter jumps** — The context meter stays at 100 % throughout the retries, then drops abruptly (84 %) once the buffered turn finishes. We currently estimate the prompt once before the first retry; recompute the `context_usage_estimate` every time we rebuild the follow-up payload so each “Continuing automatically …” turn decrements the meter incrementally. Capture telemetry showing `context_usage_estimate.total_tokens` per attempt.
- **Next steps:**
  1. Implement the slower retry cadence + telemetry and re-run the OSS TUI script to confirm each follow-up waits the expected number of seconds (record session ID).
  2. Update the fallback warning strings (exec + TUI) and verify the revised text appears in both stdout and `logs/oss-tui-run.txt`.
  3. Rework the context estimate to run per follow-up; confirm the percent-left meter now falls gradually (e.g., 100 → 95 → 90 → 84 …) across retries.
  4. Once fixed, capture a new TUI rollout and attach the snippet to `logs/oss-tui-run.txt` for posterity.

## Minimax “Worked For …” + Token Footer
- **Command:**
  ```bash
  cd ~/gh/codex-litellm/test-workspace
  CODEX_HOME=$CODEX_HOME ../codex/codex-rs/target/debug/codex
  # model selector already points to vercel/minimax-m2 (medium reasoning)
  ```
- **Expected behaviour:** The reasoning block renders in gray italics, the “Worked for …” separator appears directly before the final assistant answer, and `/quit` prints token usage + `codex resume <UUID>`.
- **Actual behaviour (rollouts `019a653c-6eaf-7b13-a8b1-39aaa2c692a9` via `codex exec` and `019a6559-9d85-7281-b69c-478a9a0d4a99` in the TUI):** Reasoning renders, but the exec transcript still duplicates the final answer and there is no token/resume footer. The TUI still prints a plain `────` divider before the final message and the “Worked for …” banner after it, and `/quit` stays silent because `TaskComplete` never fires.
- **Hypothesis:** We’re buffering the separator instead of forcing it into history whenever there’s no active stream; also, without a final assistant message the server never sends `TaskComplete`, so the CLI does not print the footer.
- **Next steps:**
  1. Ensure `insert_final_separator` falls back to a direct history insert when `stream_controller` is `None`.
  2. Promote the last reasoning text into assistant content when the SSE stream closes with `No assistant text + reasoning`, so `TaskComplete` is triggered.
  3. Re-run minimax with the new `CODEX_HOME`, capture the rollout, and verify the footer appears.

## Hand-off Checklist
- [ ] Use a fresh `CODEX_HOME` (`/root/.codex-litellm-debug-fresh` or similar) for each new batch of tests; copy `config.toml` there first.
- [x] Run the OSS exec smoke (command above) to ensure we still get the quick completion + `oss_buffered.request_elapsed_ms` log (latest session `019a78e7-f0c7-7e51-840f-580cd7992d50`). The buffered fallbacks now collapse the “We need to…”/“Continuing automatically…” chatter into grey reasoning only, and the upstream “Here’s what I just ran…” summaries are no longer emitted as black assistant bubbles.
- [ ] Reproduce the OSS TUI behaviour with the new build and capture the latest rollout ID (confirm no repeated follow-ups).
- [ ] Reproduce minimax, ensure the separator and token footer appear.
- [ ] Update this file with the new rollout IDs + findings before the next hand-off.
