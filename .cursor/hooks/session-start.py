#!/usr/bin/env python3
"""Inject current backlog work file at the start of an agent session."""
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pending_edits import empty_pending

WORK_GLOB = "*_work.md"


def current_work(backlog: Path) -> tuple[str, str]:
    if not backlog.is_dir():
        return "нет", ""
    works = sorted(backlog.glob(WORK_GLOB))
    if not works:
        return "нет", ""
    path = works[0]
    number = path.name.split("_", 1)[0]
    title = ""
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        return number, ""
    match = re.search(r"^#\s+(.+)$", text, re.MULTILINE)
    if match:
        title = match.group(1).strip()
    return number, title


def main() -> None:
    sys.stdin.read()
    empty_pending()
    number, title = current_work(Path("documents/backlog"))
    extra = f" — {title}" if title else ""
    context = (
        f"Проект «Мой питомец Мурзик». Текущий этап: {number}{extra}. "
        "Ревьюер — только по followup хука stop после правок .swift / тестов. "
        "Ask/Plan и чтение файлов ревью не запускают. "
        "Правила в .cursor/rules/ менять только после явного «принять»."
    )
    print(json.dumps({"additional_context": context}, ensure_ascii=False))


if __name__ == "__main__":
    main()
