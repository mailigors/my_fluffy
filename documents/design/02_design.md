# 02 — картинки комнаты, ласки и сна

Промпты для этапа «Комната, имя, ласка и сон». Общие правила — [design.md](design.md).

На этом этапе рисуем кота в тех состояниях, которые уже переключает комната, саму комнату днём и ночью, сердечко ласки и луну подтверждения сна. Еда и болезнь сюда не входят.

Куда класть исходники: `MyFluffy/Resources/Art/`.

## Общий промпт персонажа

Вставлять в каждый запрос кота целиком, затем добавлять строку состояния из таблицы ниже.

```text
A children's picture-book sticker of a small ginger-cream kitten named Murzik, for kids ages 3 to 7. Thick even brown outline #5B3A29, soft flat fill, no texture, no 3D, no photo. Big dark round eyes, tiny pink nose, fluffy tail, same spots and same face in every picture. Warm daylight, calm and friendly, never scared or hurt. Centered on a transparent background, square 2048x2048, generous padding so ears and tail are not cropped. No text, no letters, no watermark, no extra characters.
```

## Файлы кота

У каждого состояния 8 кадров, `01` — начало движения, `08` — конец, дальше цикл или пинг-понг. В промпт кадра добавлять: `animation frame N of 8, readable silhouette, same character as the reference`.

| Файлы | Состояние | Что происходит на кадрах |
|-------|-----------|--------------------------|
| `cat_idle_01.png` … `cat_idle_08.png` | Обычное | Сидит, моргает, слегка шевелит ушами |
| `cat_happy_01.png` … `cat_happy_08.png` | Счастливое | Кувырок и взмах лапой, из груди вылетает розовое сердечко `#FF6FA5` |
| `cat_hungry_01.png` … `cat_hungry_08.png` | Голодное | Сидит, облизывается, смотрит вниз на пустое место миски. Грустит спокойно, без слёз |
| `cat_dirty_01.png` … `cat_dirty_08.png` | Грязное | Серые мягкие пятнышки на шерсти, чешется лапой |
| `cat_bored_01.png` … `cat_bored_08.png` | Скучное | Лежит на боку и зевает |
| `cat_sleepy_01.png` … `cat_sleepy_08.png` | Сонное | Сидит, клюёт носом, глаза полуприкрыты |
| `cat_toilet_01.png` … `cat_toilet_08.png` | Хочет в туалет | Сидит, прижимает лапы, беспокоится мягко, без гримасы |
| `cat_sleeping_01.png` … `cat_sleeping_08.png` | Спит | Лежит клубочком, бок ровно дышит. Буквы «Z» не рисовать: их ставит интерфейс |

Промпт одного кадра собирается так: общий промпт персонажа, затем описание состояния, затем номер кадра. Пример для первого кадра сна:

```text
Same kitten, curled up asleep on its side, belly rising softly, eyes closed, peaceful. Animation frame 1 of 8. Transparent background, 2048x2048. No text.
```

Кадры `02`…`08` — тот же текст, меняется только номер кадра и фаза: моргание, вдох, зевок. Силуэт между соседними кадрами почти не прыгает.

## Комната и наклейки

Кот в эти файлы не входит: его спрайт ставится поверх.

| Файл | Промпт |
|------|--------|
| `room_day.png` | Children's sticker room, portrait, cream wall `#FFF6EA`, warm wooden floor, round window with a sunny garden, a low round pet bed in cream and pink `#FF6FA5`, a small empty bowl spot. Thick brown outline `#5B3A29`, soft flat fill. No kitten, no people, no text, no watermark. Bright and calm. |
| `room_night.png` | The same room and the same bed, same camera. The window is a deep calm blue night sky with a few soft yellow stars `#FFD34D` and a small moon. Room slightly dimmer, still gentle, not black, not scary. No kitten, no text. |
| `sticker_heart.png` | One chubby heart sticker, fill `#FF6FA5`, thick outline `#5B3A29`, transparent background, 512×512, centered, no text. |
| `sticker_moon.png` | One friendly round moon sticker, face with a small smile, fill `#FFD34D`, thick outline `#5B3A29`, transparent background, 1024×1024, centered, no text. |

`room_day.png` и `room_night.png` — одна и та же композиция, чтобы при засыпании менялось только окно и свет. Лежанка стоит внизу по центру: туда ложится спрайт `cat_sleeping`.
