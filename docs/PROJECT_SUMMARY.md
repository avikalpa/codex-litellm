# Project Status: Codex ↔ LiteLLM Integration  
**Updated:** 2025‑10‑26  
**Maintainer:** Codex (primary), Gemini (analysis on request)  

---

## 1. Executive Overview
- The patchset has been rebased to upstream `codex` **v0.50.0** (`stable-tag.patch`).  
- LiteLLM requests run **non-streaming**. The client buffers the JSON payload and emits synthetic `ResponseEvent`s, which resolved the hang/no-output regressions from Reports **005** and **007**.  
- Exec-mode now wraps each task in a **multi-attempt retry loop (max 5)**. If a turn ends with only fallback text (no assistant message), we surface a toast, wait 30 s, wipe the partial transcript, and re-issue the prompt so the UI never shows stale reasoning dumps.  
- Manual sampling (3x runs) no longer shows premature shutdowns; simple Q&A and the “rounded buttons” task complete without triggering the retry path.  
- LiteLLM autop-run responses are now parsed inside the client: we convert `<|start|>assistant …>` payloads into synthetic `FunctionCall` events, normalize `timeout_ms`, and default the `workdir` so tools execute as expected.
- Added safety rails for autop-run shell commands. When the model emits `grep -R …`/`find . -type f …` we automatically exclude heavyweight directories (`.git`, `.rustup`, `.cargo`, `.codex`, `.npm`, `.cache`, `.local`, `.venv`) so searches stay within the workspace and don’t walk the entire toolchain tree.
- Fallback summaries are now rendered in dim italics (matching upstream toast styling), and raw autop-run envelopes are removed from the transcript so the user only sees actionable tool events.

---

## 2. Recent Progress (Oct 24 → Oct 26)
| When | Change | Notes |
| ---- | ------ | ----- |
| Oct 24 | Repository housekeeping | `AGENTS.md` reclaimed as the active project log; instructions clarified around `CODEX_HOME`, patch generation, and CLAUDE retirement. |
| Oct 24 | Patch migration | All previous diffs consolidated into a single patch (now `stable-tag.patch`) targeting upstream release commit `63f1267d867f00f18bde079f915c4545f4c0fe9e`. |
| Oct 25 | LiteLLM streaming disabled | `core/src/chat_completions.rs` now flips `"stream": false` for LiteLLM providers and fabricates response events from the full JSON payload. |
| Oct 25 | Stability verification | Reproduced Reports 005/007 against the new build; premature termination no longer observed. |
| Oct 25 | Observability update | Added note in `AGENTS.md` clarifying that the CLI echoes assistant output twice on stdout (expected behaviour when not redirecting). |
| Oct 26 | Exec retry loop | `codex exec` main loop now detects fallback summaries, cancels the dirty turn, and resubmits the prompt (max 5 tries, 30 s wait with toast messaging). JSON output mode mirrors the same semantics. |
| Oct 26 | Rebase to 0.50.0 | Patch carried forward to upstream tag `rust-v0.50.0`, regenerating `stable-tag.patch` off commit `b4123b7b1db22a3c0a8b133a23c7b30a477d7b65`. |

---

## 3. Open Issues (as of Oct 26)
1. **Surface plan/grey reasoning inline**  
   - The upstream CLI shows incremental plan updates (dim italics) during long runs. We currently suppress most of that output; need to feed structured reasoning back through the renderer without reintroducing fallback spam.  
2. **Retry heuristics need telemetry**  
   - The generous 30 s delay + 5 attempts works in sampling, but we lack metrics to confirm whether LiteLLM actually resumes after a delayed response. Consider capturing counters in `logs/` so we can tune timing without blind guesses.
3. **Autop-run apply_patch polish**  
   - Some complex tool calls (multi-file Tailwind refactors, apply_patch scaffolds) still break into unusable fragments. We should detect these cases and either re-run or transform them into actionable patches.  
4. **Environment parity**  
   - `rg` is missing on the test image, so fallback shell commands fall back to slower `grep/find`. Either vendor `rg` into the toolchain or adjust the prompt nudges.

No other regressions are currently tracked; the `codex exec` TUI mode remains unsupported in this environment by design.

---

## 4. Next Actions
1. **Plan/Reasoning rendering**  
   - Mirror the upstream dim-italic plan summaries for long turns so users can monitor progress without triggering retries.  
2. **Instrumentation**  
   - Add counters/log metrics around retry attempts (wait duration, success/failure) so we can reason about the new loop with real data.  
3. **Regression Harness**  
   - Build fixtures from reports 005/007/011 and add tests that assert: (a) pure reasoning triggers a retry; (b) real assistant text terminates cleanly; (c) tool call payloads convert to actionable events.  
4. **Tool-call resiliency**  
   - Detect malformed apply_patch/generation payloads from LiteLLM and auto-retry or sanitize them so the user never sees raw JSON fragments.

---

## 5. Key Artifacts
- Patchset: `stable-tag.patch` (repo root)  
- Observability logs: `logs/` (latest debug traces), `test-workspace/.codex/sessions/*`  
- Configuration: `config.toml` (LiteLLM endpoint and auth), copied into each workspace-local `CODEX_HOME`  
- Test workspace: `test-workspace/` (Calibre-Web repo) for all reproduction steps

---

**Summary:** The client is stable on `codex` v0.50.0 with resilient retries and clean LiteLLM tool-call streams. Next up is exposing the upstream-style plan/grey reasoning, instrumenting retry behaviour, and hardening apply_patch-style tool calls so complex UI refactors run end-to-end without manual babysitting.
