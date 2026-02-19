# TUI Manual Smoke-Test + Telemetry Checklist

Run this checklist before handing off or publishing a build. Treat it like a
manual unit-test suite: if *any* item fails, capture the rollout ID and slice
`${CODEX_HOME}/logs/codex-tui-stream.jsonl` (via `python trace/telemetry.py tui …`)
before moving on—the telemetry log is the authoritative view of the UI.

## Preparation

1. Choose a fresh `CODEX_HOME` (copy the blessed `config.toml` into it).
2. Enable telemetry (`[telemetry] enabled = true` plus the default `tui`,
   `tui-view`, `debug`, and `session` logs) or launch with `--telemetry`.
3. Start a new `codex` TUI session (`vercel/gpt-oss-20b` first, then
   `vercel/minimax-m2`).

## Checklist Items

| # | Scenario | How to Verify |
|---|----------|---------------|
| 1 | **Reasoning dedupe + formatting** | During the OSS quicksort prompt, confirm only a single grey italic reasoning paragraph shows per turn. In telemetry, you should see exactly one `reasoning/delta`/`reasoning/complete` pair per turn; `history/ReasoningSummaryBlock` must appear once. |
| 2 | **Tool output fidelity** | Issue a `/bin/ls -a` tool call (e.g., ask “Is this a git repo?”). Inspect the TUI log’s `history/AgentMessageCell` entry to ensure the `.git` detection text matches what the model should see; no missing stdout. |
| 3 | **Buffered follow-ups** | Trigger the OSS timeout fallback (`Does this project use react?`). Confirm the `tui` log shows `history/FinalMessageSeparator` only once, retry reasonings are sequential, and the warning text matches the spec (`Press try again…`). |
| 4 | **Context meter** | In the same run, check that `status` updates in the telemetry log show decreasing `context_usage_estimate.total_tokens` per retry (no 100→84 jumps). |
| 5 | **Minimax footer** | Switch to `vercel/minimax-m2`, run the quicksort prompt, then `/quit`. Verify the TUI log contains the “Worked for …” separator before the final message and a `history/PlainHistoryCell` with the token usage footer. |
| 6 | **Git reset approval** | Ask for `git reset --hard HEAD`. Confirm telemetry captures the approval modal plus the eventual shell output, and the final assistant reply reflects that the command succeeded (no fallback to the quicksort answer). |

## Post-run

- Record the rollout ID(s) and attach the relevant snippets from
  `trace/telemetry.py tui --session <UUID> --limit 200` when filing issues.
- If any mismatch is observed, *do not* rely on screenshots—attach the
  JSONL snippets so future sweeps can replay the session exactly.
