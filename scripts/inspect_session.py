#!/usr/bin/env python3
"""
inspect_session.py

Utility to summarize Codex session JSONL logs.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict


def shorten(text: str, limit: int = 160) -> str:
    text = text.replace("\n", "\\n")
    if len(text) <= limit:
        return text
    return text[: limit - 1] + "…"


def render_event(event: Dict[str, Any]) -> str:
    timestamp = event.get("timestamp", "unknown")
    etype = event.get("type", "event")
    payload = event.get("payload", {})
    if etype == "response_item":
        rtype = payload.get("type")
        if rtype == "message":
            role = payload.get("role")
            content = payload.get("content", [])
            texts = []
            for item in content:
                if "text" in item:
                    texts.append(item["text"])
            joined = " ".join(texts)
            return f"[{timestamp}] response_item.message[{role}]: {shorten(joined)}"
        if rtype == "reasoning":
            return f"[{timestamp}] response_item.reasoning entries={len(payload.get('content', []))}"
        if rtype == "function_call":
            name = payload.get("name")
            call_id = payload.get("call_id")
            return f"[{timestamp}] response_item.function_call {name} ({call_id})"
        if rtype == "function_call_output":
            call_id = payload.get("call_id")
            return f"[{timestamp}] response_item.function_call_output ({call_id})"
    elif etype == "event_msg":
        msg_type = payload.get("type")
        if msg_type == "token_count":
            info = payload.get("info")
            return f"[{timestamp}] event_msg.token_count info={info}"
        if msg_type == "task_complete":
            message = payload.get("last_agent_message")
            return f"[{timestamp}] event_msg.task_complete last_agent_message={shorten(message or '')}"
        if msg_type in {
            "agent_message",
            "agent_reasoning",
            "user_message",
            "turn_aborted",
            "error",
        }:
            detail = payload.get("message") or payload.get("reason")
            return f"[{timestamp}] event_msg.{msg_type}: {shorten(str(detail) if detail else '')}"
    return f"[{timestamp}] {etype}: {shorten(json.dumps(payload))}"


def main() -> None:
    parser = argparse.ArgumentParser(description="Summarize codex session JSONL log.")
    parser.add_argument("session_file", type=Path, help="Path to session JSONL file")
    args = parser.parse_args()
    if not args.session_file.exists():
        raise SystemExit(f"File not found: {args.session_file}")
    with args.session_file.open() as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            event = json.loads(line)
            print(render_event(event))


if __name__ == "__main__":
    main()
