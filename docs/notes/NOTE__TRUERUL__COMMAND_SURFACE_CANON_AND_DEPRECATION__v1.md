# NOTE — Truerul command surface canon and deprecation direction (v1)

Date: 2026-03-24
Root: `/srv/truerul`

## Canonical keep (RU-first)

- Мир: `сущность`, `связь`, `состояние`
- Запрос: `запрос`, `связь?`, `сущность?`, `состояние?`
- Вид: `вид`, `схема`
- Библиотека: `категория`, `дихотомия`, `напряжение`, `карточка-цитаты`, `помощь`, `фигура`
- Мастерская: `буфер`, `блок`, `блоки`, `вставить-блок`, `выполнить-блок`, `история`, `назад`, `повторить`, `сохранить*`, `очистить`, `режим`
- Голоса/Эвристика: `голоса`, `голос`, `применить-голос`, `гипотеза`, `спор`, `заметка`, `вывод`

## Alias-only direction (keep for compatibility)

- EN heads: `entity`, `relation`, `state`, `query`, `view`, `scheme`, `help`, `history`, `back`, `repeat`, `buffer`, `block`, `insert-block`, `run-block`, `save*`.

Direction:
- do not remove now;
- treat as compatibility layer;
- keep RU heads primary in docs/help/UI.

## Reclassification

- `фигура` is reclassified as library/cultural-memory form.
- `режим` is master-workbench meta-form (language/output/voice), not ontology.

## Soft deprecation direction (not destructive now)

1. Mark figure-centric commands in UI as `legacy/cultural`.
2. Prefer voice-centric heuristic forms for future reasoning extension.
3. In next iterations, hide EN aliases from primary UI palette/help, keeping terminal compatibility.

