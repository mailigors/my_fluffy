# 02 — звуки комнаты, ласки и сна

Промпты для этапа «Комната, имя, ласка и сон». Общие правила звука — в концепции: локальные файлы, сессия не перебивает музыку телефона.

Куда класть: `MyFluffy/Resources/Audio/`.

Сейчас в игре играют заглушки `meow.caf` и `purr.caf`. Новые файлы называть как в таблице ниже. Пока их не подключат, заглушки не удалять.

## Как должны звучать

Для детей 3–7 лет, близко и тепло, как настоящий маленький кот, без мультяшного крика и без низкого гудения. Динамик телефона не должен дребезжать.

- 44,1 кГц, моно, 16 бит, контейнер `.caf`.
- Пик около −6 dBFS, без клиппинга.
- Первые и последние 15 мс — тишина с плавным входом и выходом, чтобы не было щелчка.
- Петля: конец совпадает с началом по громкости и фазе, шов не слышен.

## Общий промпт

Вставлять целиком и дописывать строку файла из таблицы.

```text
Gentle real-kitten sound for a children's app, ages 3 to 7. Close and warm, quiet, never a scream, never a cartoon zap, never a low buzzing synth, never distortion or crackle. Mono, 44.1 kHz. Peak around -6 dBFS. Fade the first and last 15 milliseconds to silence so the file does not click.
```

## Файлы

| Файл | Длина | Как играть | Добавка к промпту |
|------|-------|------------|-------------------|
| `meow_01.caf` | 0,4–0,7 с | Пробуждение, один раз | A small calm meow, medium pitch, one breath, friendly, like saying hello after a nap. One shot, not a loop. |
| `meow_02.caf` | 0,3–0,6 с | Запасное мяу | A shorter softer meow, a little higher than the first. One shot. |
| `meow_03.caf` | 0,4–0,8 с | Запасное мяу | A small meow that rises then falls, still quiet. One shot. |
| `meow_04.caf` | 0,3–0,6 с | Запасное мяу | A tiny questioning meow, two short notes, gentle. One shot. |
| `meow_05.caf` | 0,4–0,7 с | Запасное мяу | A warm meow, slightly lower, relaxed. One shot. |
| `meow_06.caf` | 0,3–0,5 с | Запасное мяу | The shortest meow, light and happy, not loud. One shot. |
| `mrr_meow.caf` | 0,5–0,9 с | Когда кот стал счастливым после ласки | A pleased mrr that opens into a soft meow. Content, not excited. One shot. |
| `purr_loop.caf` | 2–4 с | По кругу, пока палец гладит кота | A soft chest purr of a small kitten, even and cozy. Seamless loop: the end must flow into the start with no click and no gap. No meow on top. |
| `snore_loop.caf` | 2–4 с | По кругу, пока кот спит | A very quiet kitten snore, slow and even, mostly breath. Seamless loop, no click. Quiet enough to sit under the purr, not a cartoon snore. |

Текущий `snore_loop.caf` не воспроизводится: его низкие резкие звуки воспринимаются как неприятный эффект. Во сне пока звучит `purr_loop.caf` на пониженной громкости. Для отдельного звука сна нужна новая мягкая запись дыхания.

Пример целого запроса для урчания:

```text
Gentle real-kitten sound for a children's app, ages 3 to 7. Close and warm, quiet, never a scream, never a cartoon zap, never a low buzzing synth, never distortion or crackle. Mono, 44.1 kHz. Peak around -6 dBFS. Fade the first and last 15 milliseconds to silence so the file does not click. A soft chest purr of a small kitten, even and cozy, 3 seconds. Seamless loop: the end must flow into the start with no click and no gap. No meow on top.
```

Голос диктора, храп болезни и чих на этом этапе не записывать.
