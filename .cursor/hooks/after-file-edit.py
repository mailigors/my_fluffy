#!/usr/bin/env python3
"""Record source-file edits so the stop hook can trigger review + reflection."""
import json
import sys
from pathlib import Path

STATE = Path(".cursor/state")
PENDING = STATE / "pending-edits.json"
CODE_SUFFIXES = {".swift", ".py", ".plist", ".xcstrings"}


def is_skipped(posix: str) -> bool:
    return posix.startswith(".cursor/") or "/.cursor/" in posix


def main() -> None:
    raw = sys.stdin.read()
    try:
        data = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError:
        print("{}")
        return

    path = str(data.get("file_path") or "")
    posix = path.replace("\\", "/")
    if is_skipped(posix):
        print("{}")
        return

    suffix = Path(path).suffix.lower()
    if suffix not in CODE_SUFFIXES:
        print("{}")
        return

    STATE.mkdir(parents=True, exist_ok=True)
    files: list[str] = []
    if PENDING.exists():
        try:
            files = list(json.loads(PENDING.read_text(encoding="utf-8")).get("files", []))
        except (json.JSONDecodeError, OSError):
            files = []
    if posix not in files:
        files.append(posix)
    PENDING.write_text(json.dumps({"files": files}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("{}")


if __name__ == "__main__":
    main()
