# Upstream Reasoning & Status Logic (rust-v0.57.0)

This note captures how stock `openai/codex` renders reasoning and status hints in
`rust-v0.57.0`. Use it as the ground truth when re-applying our LiteLLM patches.

## Where reasoning arrives
- The client streams `ResponseEvent::Reasoning*` and
  `ResponseEvent::AgentReasoning*` events (see `codex-rs/core/src/client.rs`).
- `parse_turn_item` ( `codex-rs/core/src/event_mapping.rs` ) only maps
  `ResponseItem::Reasoning` into history after the stream finishes; deltas are
  forwarded as `AgentReasoningDelta` / `AgentReasoningRawContentDelta` UI events.

## How the TUI displays reasoning
- `ChatWidget::on_agent_reasoning_delta` (`codex-rs/tui/src/chatwidget.rs`)
  collects deltas in `reasoning_buffer`, logs them for status telemetry, and
  updates the status header. It prefers the first `**bold**` block; otherwise it
  leaves the existing header unchanged.
- No history cell is inserted until `on_agent_reasoning_final` fires. At that
  point the buffered text becomes a grey italic block via
  `history_cell::new_reasoning_summary_block`. This means users see status-line
  updates during the turn and only get the full reasoning transcript once the
  model yields.

## Status header behaviour
- The status widget shows "Working (Xs)" by default. When reasoning deltas
  arrive, the header is replaced with the extracted bold summary (e.g.,
  "Audit lock-file") until the reasoning block completes.
- Because only the status line changes, the transcript stays quiet unless the
  turn ends or the model emits an explicit assistant message.

## Fallback / timeout messaging
- When the client synthesises a fallback (e.g., timeout) it sends the text as a
  normal assistant message. The TUI does not special-case it beyond rendering it
  as a history entry.
- Explicit warnings (quota, auth, etc.) are delivered via `EventMsg::Warning`
  and rendered with `history_cell::new_warning_event` (yellow notification box).

When updating our LiteLLM patch, preserve this split: deltas update the status
header, the grey italic block is only inserted at reasoning completion, and
fallback notices should ideally use the warning pathway rather than masquerade
as normal assistant messages.

## Token meter and `/status` output
- `codex-rs/core/src/codex.rs` calls `ContextManager::update_token_info` after
  each turn. That hands a per-turn `TokenUsage` record (prompt + completion)
  to `TokenUsageInfo::new_or_append`, which keeps two values:
  - `total_token_usage`: cumulative, used for the “XX total (YY input + ZZ
    output)” line in `/status`.
  - `last_token_usage`: the most recent turn only.
- `/status` (see `codex-rs/tui/src/chatwidget.rs` + `tui/src/status/card.rs`)
  feeds `total_token_usage` into the “Tokens used” display and
  `last_token_usage` into the context meter. `StatusHistoryCell` then calls
  `TokenUsage::percent_of_context_window_remaining`, which subtracts a fixed
  12k‑token baseline before computing the remaining percentage.
- Because `last_token_usage` is per-turn, the context gauge reflects the **last
  streaming request**, not the cumulative total. The cumulative value is still
  shown separately as “total/input/output” for billing visibility.
