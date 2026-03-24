# REPORT — Truerul language stratification and three voices (v1)

Date: 2026-03-24
Repo: `/srv/truerul`

## Summary

Task focus shifted from shell-only work to language architecture.
Implemented:
- explicit language strata,
- first real three-voice contour in runtime,
- help/palette/UI reflection of families,
- cleanup/canon note for command surface.

## Exact changed files

- `lisp/src/runtime-state.lisp`
- `lisp/src/evaluator.lisp`
- `lisp/src/repl.lisp`
- `apps/web/public/index.html`
- `apps/web/public/main.css`
- `apps/web/public/client.js`
- `docs/specs/SPEC__TRUERUL__LANGUAGE_STRATIFICATION_AND_THREE_VOICES__v1.md`
- `docs/notes/NOTE__TRUERUL__COMMAND_SURFACE_CANON_AND_DEPRECATION__v1.md`
- `docs/runbooks/RUNBOOK__TRUERUL__LANGUAGE_STRATIFICATION_AND_THREE_VOICES__v1.md`
- `docs/reports/REPORT__TRUERUL__LANGUAGE_STRATIFICATION_AND_THREE_VOICES__v1.md`

## Implemented language architecture

1. Strata forms available via runtime command:
- `(слои)` / `(страты)` / `(язык)` -> layered map (Мир, Запрос, Вид, Библиотека, Мастерская, Голоса/Эвристика)

2. Canonical user flow:
- `(ритм)` / `(поток)` -> explicit 6-step rhythm

3. Cleanup/canon contour:
- `(канон)` -> what is canonical, alias-only and legacy direction

## Three voices contour (runtime, not decorative)

Built-in voices:
- `сборка` (constructive/generative)
- `предел` (critical/limiting)
- `синтез` (mediating/integrative)

Implemented forms:
- `(голоса)` list
- `(голос <имя>)` inspect
- `(голос <имя> :фокус ... :тенденции (...) :проверки (...) :ключи (...))` update
- `(режим :голос <имя>)` set active voice
- `(применить-голос <имя> <форма|тема>)` or `(применить-голос <форма|тема>)`

Heuristic contour (v1):
- `(гипотеза ...)`
- `(спор ...)`
- `(заметка ...)`
- `(вывод ...)`

## Shell/help reflection of stratification

- help output in REPL is grouped by families (not flat pile)
- left pane has explicit `Голоса` section
- palette grouped by strata with `optgroup`
- help pane includes strata + canonical rhythm shortcuts
- status line now includes `voice`

## Verification executed

- Lisp smoke passed for:
  - `(слои)`, `(ритм)`, `(канон)`
  - `(голоса)`, `(голос сборка)`
  - `(режим :голос предел)`
  - `(применить-голос предел (схема время))`
  - `(гипотеза ...)`, `(спор ...)`, `(заметка ...)`, `(вывод)`
- `node --check apps/web/public/client.js` passed
- HTML markers confirmed:
  - `Голоса`
  - `Шаблоны форм по стратам`
  - `status-voice`
  - `(слои)` action in help pane

## What remains conceptual (honest limits)

- Voice application currently gives structured heuristic guidance, not full inference engine.
- No automated multi-voice comparison matrix yet.
- Further de-emphasis of legacy figure-centric layer can continue in next iterations.

