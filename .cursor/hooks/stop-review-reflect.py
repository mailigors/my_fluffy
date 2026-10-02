#!/usr/bin/env python3
"""After a turn that changed source files, ask the agent to review and reflect once."""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import review_hashes
from pending_edits import PENDING, STATE, empty_pending

SCOPE = STATE / "review-scope.json"
REVIEW_SUFFIXES = {".swift", ".py", ".plist", ".xcstrings"}


def is_skipped(posix: str) -> bool:
    return posix.startswith(".cursor/") or "/.cursor/" in posix


def reviewable(files: list[str]) -> list[str]:
    out: list[str] = []
    seen: set[str] = set()
    for raw in files:
        posix = str(raw).replace("\\", "/")
        if is_skipped(posix):
            continue
        suffix = Path(posix).suffix.lower()
        if suffix not in REVIEW_SUFFIXES:
            continue
        if posix in seen:
            continue
        seen.add(posix)
        out.append(posix)
    return out


def followup_message(files: list[str]) -> str:
    bullets = "\n".join(f"- `{path}`" for path in files)
    return f"""Цикл качества «Мой питомец Мурзик» — строго один раз за ход.

Сначала:
- В этом ходе уже был Task(subagent_type=code-reviewer)? Да → второй Task запрещён. Рефлексия только если ещё не писал в pending.md. Краткий отчёт. Стоп.
- `python3 .cursor/hooks/review_hashes.py filter` по путям ниже. Пустой список → этот diff уже ревьюили. Не запускай Task. Стоп.
- Нет Task и список не пустой → один Task code-reviewer, model composer-2.5-fast (не inherit), только оставшиеся файлы.

Промпт субагенту — скопируй как есть:
Ревьюй ТОЛЬКО эти файлы. git diff HEAD -- <пути ниже>. Запрещено git diff HEAD без путей, concept/, knowledge/, documents/, чужой незакоммиченный дифф. Максимум 3 раунда инструментов. Смотри hunks diff, не весь файл. Не повторяй Warning/Suggestion, который уже в pending.md или в прошлом отчёте этого чата.
{bullets}

После отчёта: исправь только Critical (без второго ревьюера); `python3 .cursor/hooks/review_hashes.py record`; рефлексия; отчёт Critical / Warnings / pending.
"""


def main() -> None:
    raw = sys.stdin.read()
    try:
        data = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError:
        print("{}")
        return

    if data.get("status") != "completed":
        print("{}")
        return

    loop_count = int(data.get("loop_count") or 0)
    if loop_count >= 1:
        empty_pending()
        print("{}")
        return

    files: list[str] = []
    if PENDING.exists():
        try:
            files = list(json.loads(PENDING.read_text(encoding="utf-8")).get("files", []))
        except (json.JSONDecodeError, OSError):
            files = []

    files = review_hashes.filter_paths(reviewable(files))
    if not files:
        empty_pending()
        print("{}")
        return

    STATE.mkdir(parents=True, exist_ok=True)
    SCOPE.write_text(
        json.dumps({"files": files}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    empty_pending()
    print(json.dumps({"followup_message": followup_message(files)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
