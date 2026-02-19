# Model Behavior Notes

This file records the implementation details and known gotchas for the LiteLLM
integration so we can explain (and reproduce) the divergences from upstream
Codex. Update it whenever we patch the request/response pipeline so future
sweeps understand why the behavior differs.

## Non-Agentic First Models (OSS / buffered chat)

### Design Goals
- Maintain parity with upstream Codex when the upstream agent streams a final
  assistant message.
- When LiteLLM pauses after tool chatter (no assistant reply), synthesize a
  clean summary instead of forcing the user to resume manually.
- Keep the TUI transcript quiet: reasoning/fallback blobs should render as a
  grey italic thinking block, not as normal assistant bubbles.

### Current Implementation
1. **Buffered fetch & follow-ups**
   - OSS family (`vercel/gpt-oss-*`, etc.) runs through
     `fetch_chat_completions_buffered`.
   - All front-ends (CLI, TUI, exec) now keep a minimal follow-up budget so we
     can automatically fire “Pick up from the latest tool output…” prompts when
     the model streams tool chatter but no answer.
   - Each LiteLLM request is hard-capped at **45 seconds** regardless of the
     remaining follow-up budget. We log `oss_buffered.request_elapsed_ms` so
     stalls can be spotted immediately in `logs/oss-exec-trace.log`.
   - When we are forced to send buffered follow-ups, we now retry **five**
     times (up from three). Every retry emits a grey reasoning block,
     `Continuing automatically… (retry X/5; reason; waiting up to 45s)`, so the
     user sees progress without extra history spam. Once the limit is hit we
     send a final ⚠ warning with instructions to `/continue` manually.
   - Once a genuine assistant reply is emitted (non-fallback), we suppress the
     `NoToolWork` follow-up entirely and send a `BackgroundEvent` with the text
     “Buffered turn complete after …s” so the TUI can drop the “Working…”
     banner right away.
   - Every time we queue a buffered follow-up or tool output, we emit a
     `BackgroundEvent` (visible via `scripts/inspect_session.py`) so we can see
     exactly when the client re-requests LiteLLM.
2. **Noise filtering**
   - Autopilot text (“We need to …”, “Goal: …”, JSON tool hints such as
     `{ "command": [...] }`, `{ "path": … }`, `{ "query": … }`, MCP stubs, and
     the legacy fallback copy) is downgraded to `AgentReasoningRawContent` so
     the TUI renders it as a grey italic block and it never counts as the
     “final assistant reply”.
   - When LiteLLM forgets to emit a formal `tool_calls` block but sneaks a
     `{"command": [...]}` JSON payload inside its reasoning, we parse that blob,
     synthesize a shell tool call, and run it locally. This keeps older “OSS”
     models moving even when they boot into autopilot mode.
3. **Fallback reasoning**
   - When the buffered response contains no assistant text, we emit a
     reasoning item that summarizes the recent tool calls:
     ```
     Here’s what I just ran while checking your request:
     - ran shell command …
         ↳ output: …

     The upstream model stopped after those steps, so I can keep digging or
     apply the findings above if you need more.
    ```
   - This reasoning block is recorded in the transcript for auditing.
   - Pure tool-summary spam is collapsed into a short “Continuing
     automatically…” entry so the transcript shows progress without dumping the
     entire fallback paragraph.
   - Noise-only reasoning (anything beginning with “Continuing…” or the
     autopilot boilerplate) stays exclusively in this grey italic block. We no
     longer promote it into assistant text, preventing duplicate black bubbles
     in the TUI.
4. **Synthetic assistant reply + timeout handling**
   - As soon as the fallback reasoning fires (no useful assistant text), we
     immediately zero out the follow-up budget and inject a final assistant
     summary that acknowledges the pause and offers to retry. This prevents the
     same fallback prose from being emitted multiple times and keeps OSS turns
     from hanging forever when LiteLLM only emits autopilot chatter.
   - When the upstream model also fails to respond within 45 seconds, we emit
     the same summary so the user still receives a “Worked for …” banner and
     `/quit` footer without pressing Esc.
   - This synthetic reply fires `TaskComplete`, restoring the “Worked for …”
     separator and `/quit` token footer even after timeouts.
   - Internally verbose background events (“Queued … tool outputs for
     buffered follow-up”) are filtered before they reach the TUI/CLI so the
     history view only shows meaningful progress notices (preparing a turn,
     buffered turn complete, etc.).
5. **Token-usage metering**
   - Context usage is only updated when we record *visible* transcript items.
     Pure noise/fallback turns (grey reasoning only) no longer drain the
     context meter, so the percentage displayed in the TUI reflects the text the
     user actually saw.

### Hairy Gotchas
- LiteLLM frequently pauses after a single tool call, so we must tolerate
  multiple consecutive “tool summary” reasoning blocks without surfacing
  duplicate messages to the user.
- If we mark the fallback copy as noise *and* fail to synthesize a final
  assistant message, the exec/TUI flows appear to hang; always ensure there’s
  at least one assistant bubble before `TaskComplete`.
- Timeouts in the CLI manifest as `TurnAborted (Interrupted)`; the TUI does
  not print “Worked for …” or token stats in that code path, so long-running
  diagnostics should inject a synthetic completion before the user presses
  `Esc`.
- Five forced follow-ups are the hard cap; once the warning is emitted the UI
  will sit idle until either LiteLLM responds or the user issues `/continue`.
  Always capture the warning text + session ID in `docs/CURRENT_TASK.md` so we
  know whether the backend or our wiring caused the stall.

## Exec vs TUI test loop
- Every OSS change must be validated with:
  ```
  cd test-workspace
  CODEX_HOME=/tmp/codex-home-oss-test \
    timeout 90s ../codex/codex-rs/target/debug/codex \
    exec "Does this project use react?" \
    --model vercel/gpt-oss-20b --skip-git-repo-check
  ```
  This keeps iterations deterministic and catches obvious hangs before we hand
  the tree back for TUI validation.
- Only after the exec run completes (single assistant reply + token stats)
  should we ask the user to re-run the full TUI scenario.

## Manual Diagnostics
- When diagnosing non-agentic regressions, use the same backend credentials
  to reproduce the flow outside Codex before touching the client:
  1. `curl -H "Authorization: Bearer $TOKEN" -d '{...}' $BASE/chat/completions`
     to see the raw `tool_calls` payload.
  2. If the backend pauses after the first tool, run the `python` harness under
     `test-workspace/` to execute each command and resend the updated `messages`
     array. The script mirrors Codex’s tool runtime and exposes whether the
     model itself is emitting malformed reasoning or we dropped the follow-up
     request.
- Record the findings (session IDs + curl/python output snippets) in
  `docs/CURRENT_TASK.md` so future sweeps can replay the exact scenario.
