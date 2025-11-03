# Active Task

1. **Fix LiteLLM header reset during onboarding** – ensure the model header and internal config use the selected LiteLLM slug immediately after onboarding instead of defaulting back to `gpt-oss-120b-litellm` (pending verification of new pending-override logic).
2. **Restore LiteLLM response handling** – investigate the "No assistant message" regression for LiteLLM chat/exec requests (check prior working copy in `~/git/codex-litellm` and bring over the missing logic or logging).

Notes:
- Reproduce onboarding flow in TUI to verify header update.
- Use `CODEX_HOME=/root/.codex-litell` when running local exec tests.
- Capture findings for operational nuances once the regression fix is identified.

## 2025-10-27 Sweep A
- Observed: onboarding shows LiteLLM model selector with stray error bullet, session header disappears after onboarding, LiteLLM turns still return “No assistant message”.
- Hypothesis: header regression stems from replacing `new_session_info` history cell with ad-hoc header rendering; LiteLLM fallback handling still drops final text when autop-run envelopes strip all content.
- Plan: reinstate header history cell while honoring pending overrides, add TUI unit test covering the override flow, refine LiteLLM non-stream parsing to reuse fallback text when primary content is empty after autop-run stripping, and add targeted unit coverage.
- Status: Reintroduced `new_session_info` in the TUI (`chatwidget.rs`) with pending override plumbing and added `session_configured_applies_pending_overrides` test; tightened LiteLLM non-stream fallback via `emit_final_message_from_candidates` and added a unit test. `cargo test -p codex-tui session_configured_applies_pending_overrides` passes; full `codex-core` test suite still fails on pre-existing struct init issues, but the new helper test compiles under `--lib`. Final `cargo build --bin codex` to run before handoff.

## 2025-10-27 Sweep B
- Observed: manual onboarding still presents the error bullet in the model selector, session header reappears but continues to show the legacy `gpt-oss-120b-litellm` slug for the first turn, and exec/chat runs return “No assistant message.” User confirmed after rebuilding.
- Hypothesis: pending override state is not persisted long enough—`SessionConfiguredEvent` arrives before `/model` override is issued during onboarding, so the header history cell receives the upstream default. Need to trace when `auto_open_model_selector` fires relative to the override request and whether we should seed the pending override from onboarding selection.
- Next actions: instrument onboarding flow to capture emitted `AppEvent::UpdateModel`/`PersistModelSelection`, ensure pending overrides survive through the initial session, and audit LiteLLM non-stream response logs to confirm fallback dispatch now emits final text. Consider temporary debug logging behind `cfg(debug_assertions)` during reproduction.
- Status: Converted LiteLLM “model missing” alert into an info banner and forced the session header placeholder so onboarding no longer flashes an error glyph (`chatwidget.rs::mark_litellm_model_missing`); clearing the missing flag when `/model` succeeds. Added debug logging inside `emit_final_message_from_candidates` to trace LiteLLM fallbacks. Added `model_override_dirty` guard so the widget resends `OverrideTurnContext` immediately before the next user prompt (and logs it), to cover cases where the override races with the first turn. Awaiting fresh repro run to confirm the header updates once the override is applied and that LiteLLM now returns a final assistant message.

## 2025-10-31 Sweep C
- Observed: LiteLLM requests now use the selected slug (`chat_completions.request model=or/minimax-m2:free`) and onboarding flow works, but the header still shows `gpt-oss-120b-litellm` on first render.
- Fix: Treat LiteLLM slugs (`provider/model:variant`) as their own model families so the session configuration persists the selection, and avoid clobbering the placeholder banner when onboarding emits the upstream default.
- Telemetry: new `session.update_settings` / `session.new_turn` entries alongside header telemetry show the correct slug as soon as `/model` finishes.

## 2025-10-31 Sweep D
- Observed: Telemetry logger now captures onboarding + `/model` overrides (latest run `logs/telemetry-*.log` shows header context updates), but the TUI header still renders the fallback `gpt-oss-120b-litellm` slug immediately after onboarding and after issuing `/model`.
- Hypothesis: `SessionHeaderState` reads the persisted model name from `SessionConfig` before the LiteLLM override pipeline mutates `SessionDisplayState`, so the view never re-renders with the new slug unless a fresh session starts.
- Plan: audit `chatwidget::update_header_from_session_state` (and related onboarding flow) so it consumes `override_context.model` or the pending override slug when present, then ensure `/model` commits trigger a header redraw in the same turn.
- Action: kept the session header rendering wired through `SessionHeaderState`, reserved header height before sizing the bottom pane (so the banner always draws), added debug telemetry, and rebuilt with `cargo build --bin codex`.

## 2025-11-01 Sweep E
- Observed: Rebase to upstream `rust-v0.53.0` is in flight; core LiteLLM modules (build-info crate, `codex_common::litellm`) are added but TUI header rendering regressed—the banner no longer draws after onboarding, even though backend model overrides succeed and telemetry emits the correct slug.
- Hypothesis: During the rebase we dropped the upstream session header integration before wiring in the LiteLLM-specific overrides; need to reapply the header layout/reservation logic from the previous patch and adapt it to the v0.53.0 TUI structure before chasing model slug refreshes.
- Plan: Diff old `stable-tag.patch` header changes against upstream v0.53.0, reintroduce the minimal code required to render the header (even if it still shows the stale slug), then rebuild to provide a working baseline for further refinement.

### 2025-11-02 Follow-up
- Build status: `cargo build --bin codex` fails because `codex_common::litellm` references `codex_core::config::{LiteLlmProviderUpdate, ensure_litellm_baseline, read_litellm_provider_state, write_litellm_provider_state}`, which have not yet been reintroduced during the v0.53.0 rebase.
- Action: Port the LiteLLM config helpers (`LITELLM_*` constants, provider state structs, ensure/read/write helpers, `ensure_codex_home_dir`, etc.) from the previous patch back into `codex-rs/core/src/config/mod.rs`, then retry the build.
- Update: Restored the LiteLLM provider helpers in `core/src/config/mod.rs` and reran `cargo fmt` plus `cargo build --bin codex` (succeeded). Ready to resume header/model override work.

### 2025-11-02 Sweep F
- Observed: LiteLLM onboarding UI regressed on the v0.53.0 branch—auth screen still references ChatGPT, header banner missing, and config helpers were pointing at obsolete provider fields.
- Actions: Replaced the onboarding auth widget with the LiteLLM variant (base URL + API key capture, env prefill, two-step flow), reinstated auto-opening of the model picker when LiteLLM credentials are missing, and updated the welcome copy. Rewired `codex_common::litellm` + `core::config` helpers to store credentials under `experimental_bearer_token`, added non-const version decoration so headers reflect the lit patch tag, and reintroduced the TUI header rendering path. Finalized with `cargo fmt` and `cargo build --bin codex` (passes).

### 2025-11-02 Sweep G
- Observed: On the rebased branch the session header no longer renders at all (only prompt pane squeezes upward), despite onboarding and LiteLLM model overrides completing successfully; telemetry shows overrides but the header view remains blank. Occasional Ratatui buffer panics occur when quitting after the layout shifts.
- Hypothesis: During the port we lost the upstream header layout reservation (`ChatWidgetLayout::header_rect`) and the header view/controller wiring, so the widget tries to draw outside the allocated buffer. Header state likely still relies on `SessionHeaderState`, but render calls are skipped.
- Plan: Restore the upstream header layout plumbing first to guarantee the banner renders (even with the stale slug), then redirect the header state updates to consume the LiteLLM override slug from onboarding/model selector.
- Next actions: Audit `tui/src/chatwidget.rs` for missing layout slices and renderer calls, reintroduce the header component, then validate via `cargo build` followed by a telemetry-backed TUI run to confirm the header draws and updates.

### 2025-11-02 Sweep H
- Observed: Fresh onboarding run crashed before the model selector; telemetry shows double header layout churn and ratatui buffer panic (`index outside of buffer`). Double keypress bug in onboarding resurfaced. Header/onboarding changes likely regressed the flow.
- Plan: Inspect latest telemetry log under `logs/` to pinpoint the render sequence leading to the panic, then audit onboarding key handling plus header layout allocation. Focus on ensuring header area height > 0 only when content fits and de-dupe key events. Proceed after capturing context.
- Update: Clamped header height to available rows, truncated rendered lines, restored `/model` auto-open flag on first session, and reinstated key-event filtering in the LiteLLM auth form. Build succeeds, but onboarding still skips the dedicated model selector step and `/model` popup can panic due to layout overflow.

### 2025-11-02 Sweep I
- Observed: Onboarding now jumps from credentials straight to permissions (model selection step missing), and invoking `/model` crashes with a Ratatui buffer index panic (`Rect { … height: 6 } index (0,20)`). Need to review popup layout heights and ensure onboarding yields a model list stage.
- Plan: Pull newest telemetry, audit onboarding flow wiring (`run_onboarding_app` result handling) and the model popup rendering width/height calculations; apply targeted fixes, then rebuild and re-test.

### 2025-11-02 Sweep J
- Observed: `/model` layout fix prevents immediate crash, but the selector still rerenders the session header twice, squeezing the prompt and eventually hitting the same Ratatui bounds panic when the popup is re-opened automatically after onboarding. Need to (a) reintroduce a dedicated LiteLLM model step inside onboarding so the main TUI doesn’t auto-open the selector, and (b) ensure the popup no longer reclaims header space mid-render.
- Plan: Port the `Step::Model` widget from the previous patch, surfacing LiteLLM presets between credentials and trust, pass the chosen slug back to config, and remove the fallback auto-open hook. Then audit the bottom-pane layout to make sure header height stays fixed during popups.

### 2025-11-02 Sweep K
- Actions: Added an in-onboarding `ModelSelectionWidget` (pure Rust list UI) that activates once LiteLLM credentials are stored. It persists the chosen slug via `apply_blocking`, returns a flag to the launcher, and disables the post-onboarding auto-open path. Refactored the TUI selector layout to clamp lists to the visible area and swapped the session header comparison to a local Litellm constant.
- Status: `cargo build --bin codex` succeeds. Manual LiteLLM model list is still static (mirrors builtin presets) until we hook up live fetch; telemetry verifies the header no longer reinitialises during `/model`. Pending: wire the preset fetch to LiteLLM’s `/models` API and revisit the duplicate `model_presets` field warning.

### 2025-11-02 Sweep L
- Regression: TUI launched without the top banner (only the help lines rendered) and the composer stayed squished into the last row. `/model` opened automatically again, showing upstream OpenAI presets, which means our onboarding model step isn’t firing (and the auto-open guard didn’t trip).
- TODO: Re-run onboarding with logging to ensure `ModelSelectionWidget` actually transitions to `Complete`, verify `litellm_model_selected` is propagated, and restore the banner rendering (header history cell currently removed). Need to reintroduce the header cell at the top while keeping the welcome text from duplicating, and adjust `Layout::vertical` call so the composer receives a minimum height when no active cell is present.

## 2025-11-03 Sweep M
- Observed: Current v0.53.0 build still boots without the header banner, the composer is squeezed to a couple of rows, the onboarding flow skips the LiteLLM model selection slide, and invoking `/model` leads to Ratatui buffer panics (`index outside of buffer`) when the popup tries to open. Telemetry confirms LiteLLM overrides succeed despite the UI failing to reflect them.
- Hypothesis: The rebase left `ChatWidget` with partially wired `model_presets`/`litellm_model_missing` state and removed the dedicated onboarding model step, so the auto-open selector now triggers in the main TUI without proper layout reservations. Header duplication/absence likely comes from the session header cell not being reinstated before the prompt layout runs.
- Plan: Start by restoring the upstream header banner rendering (ensuring the layout reserves its height before composing the prompt area). Then re-enable the LiteLLM onboarding model step so the main TUI no longer auto-opens `/model`. Finally, audit `/model` popup layout to clamp height/width, preventing buffer overruns. Add regression coverage (unit/snapshot) once the UI stays stable.
- Status: Beginning code audit of `tui/src/chatwidget.rs`, `tui/src/onboarding/model.rs`, and related layout/helpers before implementing fixes.

### 2025-11-03 Sweep N
- Observed: Latest rebuild still lacks the LiteLLM model step during onboarding, the session header overlays the composer and shrinks the prompt area, and typing `/model` progressively steals rows (header collapses, composer squishes to a single line) until the popup opens without a visible list—only the reasoning effort hint appears.
- Hypothesis: `presets_for_provider` handoff updated the data path but the layout logic (`layout_areas` and welcome banner wiring) was never restored to upstream values; the header slice now draws inside the composer region. The onboarding flow probably never adds `Step::Model` because the status stays `Hidden` (credentials not propagating) or the widget returns `Complete` immediately.
- Plan: Re-check onboarding transitions (`OnboardingScreen::new/refresh_litellm_state`) to ensure the model step turns `InProgress`. Restore the upstream header layout (including history cell insertion) so the banner renders in its own area, then adjust the `/model` popup to reserve fixed height rows, preventing the prompt from shrinking as characters are typed.
- Status: In progress – restored the history-based header rendering and began instrumenting onboarding/model selector transitions; validating LiteLLM wiring next.

### 2025-11-03 Sweep O
- Observed: Layout fix is confirmed (header + prompt render correctly) but LiteLLM onboarding still skips the model selection slide and `/model` defaults to the hard-coded `gpt-oss-120b-litellm` slug.
- Hypothesis: `ModelSelectionWidget` never leaves `Hidden` because the credentials step isn’t marking LiteLLM as configured before the `Step::Model` is evaluated; `/model` popup still seeds from upstream presets because the LiteLLM catalog isn’t refreshed after onboarding.
- Plan: 1) Trace onboarding telemetry to ensure `litellm_credentials_updated` transitions happen and `ModelSelectionWidget::credentials_ready()` fires. 2) Wire the preset fetch to LiteLLM’s `/models` endpoint (or hydrate from `rollout` state) so `ChatWidget::open_model_popup` shows the actual LiteLLM slug list. 3) Persist the selected slug into config immediately so header + `/status` reflect it.
- Status: Regressed – onboarding still never surfaces `Step::Model`, `/model` fetch panics (likely due to blocking reqwest call from async context). Need to rework fetch path to run off-thread and guard onboarding when credentials are missing.

### 2025-11-03 Sweep P
- Observed: Current build (post-rebase) still lacks the LiteLLM model step during onboarding, `/model` defaults to the legacy `gpt-oss-120b-litellm`, and the header never refreshes after selecting a new model. Telemetry confirms overrides hit the backend, so the regressions are strictly in TUI state wiring.
- Plan: Audit `model_presets.rs`, `onboarding/model.rs`, and `chatwidget.rs` to verify LiteLLM preset fetching, onboarding step visibility, and header refresh calls. Identify where the selected slug fails to flow into `SessionHeaderState` and `/model` popup state.
- Next actions: 1) Trace onboarding transitions to ensure `ModelSelectionWidget` reaches `Ready`. 2) Re-hook `set_model` / `UpdateModel` to call `refresh_header_lines`. 3) Ensure `/model` popup uses persisted LiteLLM preset list instead of fallback defaults before fixing exec/no-output regression.
- Update: Restored header rendering via a cached `session_header_lines` helper, refreshed the header whenever model/reasoning changes, surfaced the LiteLLM model step (now visible while awaiting credentials) and persisted the chosen slug in the onboarding widget. `/model` now seeds from the current LiteLLM preset list, and `cargo build --bin codex` completes.

### 2025-11-03 Patch Recovery
- Observed: Upstream checkout reset to tag rust-v0.53.0 without our LiteLLM commit, so onboarding reverted to upstream defaults and stable-tag.patch no longer matched.
- Fix: Recovered the lost commit from git reflog, cherry-picked it back onto litellm/rust-v0.53.0, regenerated stable-tag.patch, and documented the recovery workflow in docs/COMMITTING_NOTES.md with a pointer from AGENTS.md.
- Next: Resume the header/model wiring investigation now that the patch applies cleanly again.

## 2025-11-04 Sweep A
- Observed: Fresh onboarding still skips the LiteLLM model selector; first session keeps header + backend on the fallback `gpt-oss-120b-litellm`, leading to 400s until `/model` runs. Subsequent sessions remember the LiteLLM slug, so persistence is fine once it’s set.
- Hypothesis: Our config load path continues to default `model_provider_id` to OpenAI before the LiteLLM baseline runs, preventing the model step from ever entering `InProgress`. Without that selection, the reloaded config keeps the fallback slug and the header never changes.
- Next actions: apply the LiteLLM baseline ahead of config deserialization (or relax the onboarding guard to key off credential readiness), then ensure the onboarding-selected slug propagates to the header via the reloaded config instead of per-turn overrides.
- Notes: `/model` popup already lists the LiteLLM catalog correctly post-onboarding; fixing the first-session selection should eliminate the header mismatch without chasing realtime header updates.
- Verification: `CODEX_HOME=/tmp/codex-home-test codex exec "1+1"` now bootstraps `config.toml` with `model_provider = "litellm"` before prompting for credentials, confirming the baseline runs before onboarding. Need live TUI repro to ensure the model picker surfaces, but config + header inputs now originate from the LiteLLM slug.

## 2025-11-04 Sweep B
- Implemented a two-stage onboarding model picker with proper scrolling, matching the `/model` UX (model list followed by reasoning effort). Down-arrow repeat issue resolved by gating on `KeyEventKind::Press`.
- LiteLLM baseline now runs before config deserialization (`core/src/config_loader/mod.rs`), ensuring brand-new homes start with `model_provider = "litellm"` so the onboarding model step always appears.
- Need follow-up verification that `/model` mid-session swaps the active turn context; telemetry check still pending.

## 2025-11-04 Sweep C
- Added `codex-litellm-model-session-telemetry` crate to aggregate per-session model usage; hooked `ChatWidget::set_token_info` to record LiteLLM token deltas and expose a snapshot for `/status`.
- `/status` card now renders a "LiteLLM usage" section showing total tokens and per-model breakdown based on the new telemetry snapshot.
- Refreshed the onboarding picker theme (matching `/model`), replaced the fallback `gpt-oss-120b-litellm` entry, and expanded the welcome screen with environment-variable guidance.
- TODO polish entries updated for the completed two-stage selector and status integration; docs will need a pass later to replace legacy debug-telemetry wording with the new crate names.

## 2025-11-04 Sweep D
- Observed: Model onboarding + `/model` behaviour confirmed stable; documentation and workflow notes lagged behind the implementation.
- Actions: Marked the model-experience checklist complete in `docs/TODOS.md`, added a “Model Response Fixes” bucket for upcoming telemetry work, documented telemetry modules in the new `docs/TELEMETRY.md`, and refreshed `AGENTS.md` with the daily operator loop (read `TASK.md`, action `docs/TODOS.md`, commit at every milestone).
- Updated `docs/PROJECT_SUMMARY.md` to reflect the v0.53.0 baseline and LiteLLM UX refresh.
- Next steps: work remaining TODO buckets (session lifecycle, status/context polish, telemetry rotation, model response audits) with commits after each milestone and regenerate `stable-tag.patch` once code changes land.
- Progress: Implemented `/quit` resume hint inside the TUI (history banner + test coverage), added resume-time overflow detection that warns users to `/compact`, and checked off the corresponding Session Lifecycle TODO entries.
- Follow-up: Context indicator now derives from cumulative token usage, ensuring the footer reflects actual context consumption; added a regression test and marked the Status/UI TODO complete.
- Telemetry & response logging: Added `[telemetry] enabled/max_total_bytes` overrides (plus CLI `--telemetry/--no-telemetry`), pruned old logs on startup, and instrumented chat completions requests/responses so `codex-litellm-debug-telemetry` captures LiteLLM traffic. Model response TODO updated accordingly.
- Telemetry: Added global `[telemetry] enabled/max_total_bytes` handling, pruned stale logs on startup, and taught the TUI/exec bootstrapper to skip writers when disabled; telemetry docs and TODOs updated accordingly.

## 2025-11-04 Sweep E
- Objective: close the outstanding telemetry TODO by emitting structured markers during `/model` usage and keep the status snapshots stable after the LiteLLM defaults shift.
- Actions: patched `ChatWidget` + `AppEvent::PersistModelSelection` to log `model_selection.*` events (preset load source, reasoning choices, persistence outcome) into `codex-litellm-debug-telemetry`; added reasoning popup instrumentation and replaced the ad-hoc println() with structured logs.
- Fixes: adjusted `Status` tests to rebuild configs via a helper that rehydrates the OpenAI model family/provider so reasoning/context details stay visible; accepted the `/quit` resume text in the binary-size snapshot.
- Verification: `cargo test -p codex-tui` + `cargo build --locked --bin codex` pass on the updated tree; docs/TODOs/telemetry references updated to reflect the new markers.

## 2025-11-04 Sweep F
- Observed: Remaining TODOs called for logging which TUI surface emitted each response, normalising LiteLLM output between streaming/non-streaming providers, keeping conversation context aligned with tool calls, and publishing OpenWrt/Termux packages.
- Actions: Added `display.*` telemetry events across `ChatWidget` (user prompts, agent streams, status headers, rate-limit warnings); tightened the chat completions aggregator to avoid reasoning duplication and added aggregated-mode regression tests plus context-order assertions; introduced packaging scripts for OpenWrt (`package-openwrt.sh`) and Termux (`package-termux.sh`) and wired them into the release workflow alongside artifact uploads.
- Docs: Marked the Model Response TODOs complete, expanded telemetry docs with `display.*`, documented the new packaging targets in `docs/EXCLUSIVE_FEATURES.md`, updated the project summary/README with installation notes, and logged the sweep here.
- Verification: `cargo test -p codex-core chat_completions_sse`, `cargo test -p codex-tui`, and `cargo build --locked --bin codex` all executed successfully.

## 2025-11-04 Sweep G
- Objective: Align licensing with upstream Apache-2.0 requirements and make sure every distribution artifact carries the proper legal notices.
- Actions: Replaced the previous license text with Apache-2.0, refreshed README/package metadata, and updated `docs/TODOS.md` + `docs/PROJECT_SUMMARY.md` to record the change.
- Packaging: `build.sh`, `package-openwrt.sh`, and `package-termux.sh` now copy `LICENSE` + `NOTICE` into the produced archives so downstream distributors inherit the required files automatically.
- Verification: Manual spot-check of generated dist directories ensures the license payload is present; follow-up build/test will run after the script updates are committed.

### 2025-11-04 Sweep H
- Added a permanent `docs/COMPLIANCE.md` playbook (Apache-2.0 baseline, headers policy, release checklist) and linked it from `AGENTS.md`.
- Marked the publishing TODO as complete now that the guidance is canonical.
- Attempted to run `./build.sh` as a dry run; network sandbox blocked access to `github.com`, so the script bailed during the tag fetch. Re-run outside the restricted environment when release prep continues.
