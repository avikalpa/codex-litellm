# TUI Telemetry Checklist

Run this before handoff when a change affects rendering, reasoning display, tool-loop visibility, or finalization.

## Setup
1. Use a fresh `CODEX_HOME` with telemetry enabled.
2. Start from a clean `test-workspace` when the prompt requires repo edits.
3. Treat `logs/codex-tui-stream.jsonl` as the rendering source of truth.

## Checks
1. Reasoning formatting
- reasoning appears as reasoning, not plain assistant output
- no duplicate reasoning blocks for the same turn

2. Tool-output fidelity
- tool results visible to the user match the model-visible results closely enough to explain subsequent behavior

3. Finalization
- after a successful edit, the UI shows a clear final assistant answer
- the session does not get stuck in post-edit read-only exploration

4. Footer and completion state
- the turn reaches a clear completed state
- token/context footer behavior remains sane

5. Telemetry coherence
- `trace/telemetry.py tui --session <uuid>` and session logs explain the visible UI state without relying on screenshots or pasted transcripts

## Failure Rule
If one of these checks fails, capture the session id and log paths in `agent_docs/CURRENT_TASK.md` before patching.
