#!/usr/bin/env python3
"""
Telemetry helper for codex-litellm.

This CLI behaves like a lightweight dtrace/dmesg layer on top of Codex
session JSONL logs. It lets us list recent sessions, slice events by type,
and grep for specific reasoning/status chatter without hand-scrolling
through multi-megabyte files.
"""

import argparse
import datetime as dt
import json
import os
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Iterator, List, Optional, Sequence, Tuple


SESSION_GLOB = "sessions/*/*/*/*.jsonl"
DEFAULT_HOME = os.environ.get("CODEX_TRACE_HOME") or os.path.expanduser(
    "~/.codex-litellm-debug"
)


@dataclass
class SessionMeta:
    session_id: str
    timestamp: dt.datetime
    model: Optional[str]
    path: Path


def iter_session_files(root: Path) -> List[Path]:
    return sorted(
        root.glob(SESSION_GLOB),
        key=lambda p: p.stat().st_mtime,
        reverse=True,
    )


def parse_session_meta(path: Path) -> SessionMeta:
    session_id = "unknown"
    ts = dt.datetime.fromtimestamp(path.stat().st_mtime, tz=dt.timezone.utc)
    model = None

    try:
        with path.open() as handle:
            for line in handle:
                try:
                    record = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if record.get("type") == "session_meta":
                    payload = record.get("payload", {})
                    session_id = payload.get("id", session_id)
                    timestamp = payload.get("timestamp")
                    if timestamp:
                        try:
                            ts = dt.datetime.fromisoformat(timestamp.replace("Z", "+00:00"))
                        except ValueError:
                            pass
                    model = payload.get("model") or payload.get("model_provider")
                    break
    except FileNotFoundError:
        pass

    return SessionMeta(session_id=session_id, timestamp=ts, model=model, path=path)


def resolve_session_path(home: Path, identifier: str) -> Path:
    candidate = Path(identifier)
    if candidate.exists():
        return candidate

    needle = identifier.lower()
    matches = sorted(home.glob(f"sessions/*/*/*/*{needle}*.jsonl"))
    if not matches:
        raise SystemExit(f"no session file found for '{identifier}' under {home}")
    if len(matches) > 1:
        # choose most recent
        matches.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    return matches[0]


def load_records(path: Path) -> Iterator[Tuple[int, dict]]:
    with path.open() as handle:
        for idx, line in enumerate(handle, 1):
            line = line.strip()
            if not line:
                continue
            try:
                yield idx, json.loads(line)
            except json.JSONDecodeError:
                continue


def summarize_sessions(args: argparse.Namespace) -> None:
    home = Path(args.home).expanduser()
    files = iter_session_files(home)
    if args.limit:
        files = files[: args.limit]

    if not files:
        print(f"No sessions found under {home}", file=sys.stderr)
        return

    print(f"Sessions under {home}:")
    for path in files:
        meta = parse_session_meta(path)
        rel = path.relative_to(home)
        ts = meta.timestamp.strftime("%Y-%m-%d %H:%M:%S")
        model = meta.model or "unknown-model"
        print(f"- {meta.session_id} | {ts} | {model} | {rel}")


def format_event(record: dict, width: int = 96, body: bool = True) -> str:
    timestamp = record.get("timestamp", "?")
    kind = record.get("type", "?")
    payload = record.get("payload", {})

    preview = ""
    if isinstance(payload, dict):
        if "message" in payload:
            preview = payload["message"]
        elif "text" in payload:
            preview = payload["text"]
        elif "type" in payload and isinstance(payload["type"], str):
            preview = payload["type"]
    elif isinstance(payload, str):
        preview = payload

    if not body:
        preview = ""

    if preview:
        preview = preview.replace("\n", "\\n")
        if len(preview) > width:
            preview = preview[: width - 1] + "…"
        return f"{timestamp} {kind:32s} {preview}"
    return f"{timestamp} {kind}"


def filter_matches(record: dict, args: argparse.Namespace) -> bool:
    if args.types:
        allowed = {t.strip() for t in args.types.split(",")}
        if record.get("type") not in allowed:
            return False
    if args.contains:
        payload = record.get("payload", {})
        haystack = json.dumps(payload, ensure_ascii=False)
        if args.contains not in haystack:
            return False
    return True


def show_events(args: argparse.Namespace) -> None:
    home = Path(args.home).expanduser()
    path = resolve_session_path(home, args.session)
    if args.header:
        meta = parse_session_meta(path)
        print(
            f"# Session {meta.session_id} | model={meta.model} | "
            f"time={meta.timestamp.isoformat()} | file={path}"
        )
    count = 0
    for line_no, record in load_records(path):
        if not filter_matches(record, args):
            continue
        if args.json:
            print(json.dumps(record, ensure_ascii=False))
        else:
            print(format_event(record, width=args.width, body=not args.no_body))
        count += 1
    if count == 0:
        print("No matching events.", file=sys.stderr)


def summarize_events(args: argparse.Namespace) -> None:
    home = Path(args.home).expanduser()
    path = resolve_session_path(home, args.session)
    counts = {}
    reasoning_count = 0
    assistant_count = 0

    for _, record in load_records(path):
        kind = record.get("type")
        counts[kind] = counts.get(kind, 0) + 1
        if kind == "event_msg":
            payload = record.get("payload", {})
            if payload.get("type", "").startswith("agent_reasoning"):
                reasoning_count += 1
        if kind == "response_item":
            payload = record.get("payload", {})
            if payload.get("type") == "message" and payload.get("role") == "assistant":
                assistant_count += 1

    print(f"Summary for {path}:")
    for kind, val in sorted(counts.items()):
        print(f"- {kind:16s}: {val}")
    print(f"- reasoning events : {reasoning_count}")
    print(f"- assistant replies: {assistant_count}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Inspect Codex telemetry/log sessions.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--home",
        default=DEFAULT_HOME,
        help="CODEX_HOME-like directory containing sessions/* JSONL logs.",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    list_parser = sub.add_parser(
        "list", help="List recent sessions under the telemetry home."
    )
    list_parser.add_argument("--limit", type=int, default=20, help="Limit number.")
    list_parser.set_defaults(func=summarize_sessions)

    events_parser = sub.add_parser(
        "events", help="Show events for a given session (with filters)."
    )
    events_parser.add_argument(
        "--session",
        required=True,
        help="Session ID or direct path to the .jsonl file.",
    )
    events_parser.add_argument(
        "--types",
        help="Comma-separated list of event types to include "
        "(e.g. event_msg,response_item).",
    )
    events_parser.add_argument(
        "--contains",
        help="Only show events whose payload contains this substring.",
    )
    events_parser.add_argument(
        "--width", type=int, default=96, help="Preview width for payload text."
    )
    events_parser.add_argument(
        "--json", action="store_true", help="Print raw JSON instead of formatted rows."
    )
    events_parser.add_argument(
        "--no-body", action="store_true", help="Hide payload previews."
    )
    events_parser.add_argument(
        "--header",
        action="store_true",
        help="Print session metadata header before events.",
    )
    events_parser.set_defaults(func=show_events)

    summary_parser = sub.add_parser(
        "summary", help="Count event types for a given session."
    )
    summary_parser.add_argument("--session", required=True)
    summary_parser.set_defaults(func=summarize_events)

    return parser


def main(argv: Optional[Sequence[str]] = None) -> None:
    parser = build_parser()
    args = parser.parse_args(argv)
    args.func(args)


if __name__ == "__main__":
    main()
