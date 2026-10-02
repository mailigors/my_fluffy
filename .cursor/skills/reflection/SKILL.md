---
name: reflection
description: Post-edit reflection for the Murzik pet game. Use after code-reviewer finishes. Proposes Cursor rules to pending.md only. Never writes .cursor/rules unless the user says принять. Also handles принять / отклонить for pending proposals.
---

# Рефлексия и ручное принятие правил

Запускай **только после ревьюера** в том же ходе (followup хука `stop`). Ask/Plan и ходы без ревьюера — не пиши в pending. Также когда пользователь пишет «принять» или «отклонить» про правила.

## После правок
Не применяй правила сам. Запиши предложения в `.cursor/reflections/pending.md`. Не читай `archive.md`.

Формат одного предложения:

```markdown
## Правило N — <имя-файла.mdc>
- **Статус:** pending
- **Зачем:** одна фраза
- **Когда:** alwaysApply или globs
- **Текст правила:** короткий actionable абзац (лучше пример чем/как)
```

Пиши правило, только если оно повторится. Не дублируй `core.mdc` и не предлагай то, что уже в `.cursor/rules/` или в pending. Максимум 3 новых предложения за ход. Если извлекать нечего — секция «Предложений нет» и стоп.

В конце ответа пользователю: есть ли pending и как принять («принять правило N», «принять все», «отклонить N»).

## Принятие (только эти фразы)
«принять правило N» / «принять все» / «отклонить N»

1. Прочитай pending (не archive).
2. Принять: впиши в существующий доменный `.mdc` (`core` / `game-logic` / `game-ui` / `services` / `testing` / `backlog`), статус `accepted`. Новый файл — только если не подходит ни один домен, текст < 80 строк.
3. Отклонить: статус `rejected`, не создавай файл.
4. Не меняй формулировку при принятии, кроме YAML-frontmatter.

Без этих фраз **запрещено** создавать или править `.mdc` в `.cursor/rules/`.
