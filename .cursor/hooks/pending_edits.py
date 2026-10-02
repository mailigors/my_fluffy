"""Shared pending-edits.json helpers for review-cycle hooks."""
from __future__ import annotations

import json
from pathlib import Path

STATE = Path(".cursor/state")
PENDING = STATE / "pending-edits.json"


def empty_pending() -> None:
    STATE.mkdir(parents=True, exist_ok=True)
    PENDING.write_text(
        json.dumps({"files": []}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
