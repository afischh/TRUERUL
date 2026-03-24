# SPEC — Truerul language stratification and three voices (v1)

Date: 2026-03-24
Root: `/srv/truerul`

## 1) Canonical strata

### A. Мир (ontology/world core)
- `сущность`
- `связь`
- `состояние`

Role:
- build the primary world fragment.

### B. Запрос (inspection/query)
- `запрос`
- query heads: `связь?`, `сущность?`, `состояние?`

Role:
- inspect world without changing it.

### C. Вид (presentation/composition)
- `вид`
- `схема`

Role:
- render structure and readable composition.

### D. Библиотека (memory/resources)
- `категория`
- `дихотомия`
- `напряжение`
- `карточка-цитаты`
- `помощь`
- `фигура` (legacy cultural memory)

Role:
- open accumulated conceptual memory.

### E. Мастерская (workbench/operations)
- `буфер`
- `блок`
- `блоки`
- `вставить-блок`
- `выполнить-блок`
- `история`
- `назад`
- `повторить`
- `сохранить`
- `сохранить-вид`
- `сохранить-таблицу`
- `сохранить-схему`
- `очистить`
- `режим`

Role:
- run and preserve work cycle.

### F. Голоса / Эвристика (future reasoning contour)
- `голоса`
- `голос`
- `применить-голос`
- `гипотеза`
- `спор`
- `заметка`
- `вывод`

Role:
- apply reasoning stances and heuristic comparison passes.

## 2) Three voices

Voices are not characters. They are configurable stances:

1. `сборка` — constructive/generative mode  
2. `предел` — critical/limiting/check mode  
3. `синтез` — mediating/structural integration mode  

Current contour:
- inspect all voices: `(голоса)`
- inspect one voice: `(голос <имя>)`
- update voice traits:
  - `(голос <имя> :фокус ... :тенденции (...) :проверки (...) :ключи (...))`
- set active voice:
  - `(режим :голос <имя>)`
- apply voice to contour:
  - `(применить-голос <имя> <форма|тема>)`
  - or with active voice: `(применить-голос <форма|тема>)`

## 3) Canonical user flow

1. Open library resource.
2. Build world fragment.
3. Query and verify.
4. Render view/scheme.
5. Save block/artifact.
6. Apply voice/heuristic pass if needed.

## 4) UI implications

Workbench should reflect strata directly in:
- help
- command palette groups
- left navigation semantics
- status line (includes active voice)

## 5) Architectural boundaries

- Authors/figures remain allowed in cultural memory (library), but are not the core reasoning engine.
- Core future engine is voices + heuristic layer over a stratified language.
- EN heads remain compatibility aliases; RU heads are canonical surface.

