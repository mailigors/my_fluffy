#!/usr/bin/env python3
"""Skip files whose git diff HEAD was already reviewed this working tree."""
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
from pathlib import Path

STATE = Path(".cursor/state")
REVIEWED = STATE / "reviewed.json"
SCOPE = STATE / "review-scope.json"


def rel(path: str) -> str:
    raw = Path(path)
    try:
        return str(raw.resolve().relative_to(Path.cwd().resolve())).replace("\\", "/")
    except ValueError:
        return str(path).replace("\\", "/")


def diff_bytes(path: str) -> bytes:
    result = subprocess.run(
        ["git", "diff", "HEAD", "--", path],
        capture_output=True,
        check=False,
    )
    return result.stdout or b""


def diff_sha(path: str) -> str:
    payload = diff_bytes(path)
    if not payload:
        return ""
    return hashlib.sha256(payload).hexdigest()


def load_reviewed() -> dict[str, str]:
    if not REVIEWED.exists():
        return {}
    try:
        data = json.loads(REVIEWED.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return {}
    files = data.get("files") if isinstance(data, dict) else {}
    if not isinstance(files, dict):
        return {}
    return {str(key): str(value) for key, value in files.items()}


def save_reviewed(files: dict[str, str]) -> None:
    STATE.mkdir(parents=True, exist_ok=True)
    REVIEWED.write_text(
        json.dumps({"files": files}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def needs_review(path: str, known: dict[str, str] | None = None) -> bool:
    key = rel(path)
    digest = diff_sha(path)
    if not digest:
        return False
    remembered = (known or load_reviewed()).get(key)
    return remembered != digest


def filter_paths(paths: list[str]) -> list[str]:
    known = load_reviewed()
    out: list[str] = []
    seen: set[str] = set()
    for raw in paths:
        key = rel(raw)
        if key in seen:
            continue
        seen.add(key)
        if needs_review(raw, known):
            out.append(raw)
    return out


def record_paths(paths: list[str]) -> list[str]:
    known = load_reviewed()
    recorded: list[str] = []
    for raw in paths:
        digest = diff_sha(raw)
        if not digest:
            continue
        key = rel(raw)
        known[key] = digest
        recorded.append(key)
    save_reviewed(known)
    return recorded


def paths_from_scope() -> list[str]:
    if not SCOPE.exists():
        return []
    try:
        data = json.loads(SCOPE.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return []
    files = data.get("files") if isinstance(data, dict) else []
    if not isinstance(files, list):
        return []
    return [str(item) for item in files]


def main() -> None:
    command = sys.argv[1] if len(sys.argv) > 1 else "filter"
    paths = [item for item in sys.argv[2:] if not item.startswith("-")]
    if not paths:
        paths = paths_from_scope()
    if command == "record":
        recorded = record_paths(paths)
        print(json.dumps({"recorded": recorded}, ensure_ascii=False))
        return
    remaining = filter_paths(paths)
    print(json.dumps({"files": remaining}, ensure_ascii=False))


if __name__ == "__main__":
    main()
