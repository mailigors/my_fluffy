---
name: code-reviewer
description: Reviews the Murzik pet game Swift changes once per turn. Launch only on stop-hook followup; skip unchanged diffs via review_hashes.py.
---

# Ревьюер «Мой питомец Мурзик»

## Один запуск за ход

Единственный триггер — followup хука `stop` (список файлов в сообщении). Ask, Plan, чтение, грязный git без этого followup — не запускай Task.

- **Не** вызывай `Task(code-reviewer)` в середине фичи: хук и есть этот шаг.
- Если в **этом ходе** уже был `Task` с `subagent_type: code-reviewer` — второй **запрещён**. На повторный followup: рефлексия (если ещё нет) или короткий отчёт. Стоп.
- Перед Task: `python3 .cursor/hooks/review_hashes.py filter` и пути из сообщения. Пустой `files` → этот diff уже ревьюили, Task не запускай, короткий отчёт «без нового diff». Стоп.
- Повтор пользовательского «Цикл качества» при тех же хешах — не запускай Task.
- Docs / rename / `.cursor/` / только `pbxproj` — не запускай.

## Как запустить (когда хук просит, Task ещё не было, filter не пустой)

1. `Task`, `subagent_type: code-reviewer`, `model: composer-2.5-fast` (не `inherit`).
2. Промпт: только файлы из **filter**, не исходный полный список. Явно: `git diff HEAD -- <эти пути>`; не ревьюить чужой незакоммиченный дифф; не читать `concept/`, `knowledge/`, `documents/`; hunks, не весь файл; не повторять pending.md.
3. Типа нет — `generalPurpose` с `.cursor/agents/code-reviewer.md` и тем же списком.

## После отчёта

- Critical — минимальный патч.
- Warnings — перечислить, не чинить пачкой.
- `python3 .cursor/hooks/review_hashes.py record` (пути из scope / filter).
- Не коммитить. Не трогать `.cursor/rules/`.
- Второй `Task(code-reviewer)` после патча Critical **не** запускать.

Затем skill `reflection` — только если в этом ходе был ревьюер.
