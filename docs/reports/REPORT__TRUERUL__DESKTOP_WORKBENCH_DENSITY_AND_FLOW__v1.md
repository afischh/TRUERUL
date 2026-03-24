# REPORT — Truerul desktop workbench density and flow (v1)

Date: 2026-03-24
Repo: `/srv/truerul`

## Result

Workbench upgraded to denser v1.5 contour with better flow around the live console heart:
- clean execution is practical by default,
- completion/palette is more useful,
- schemes are clearer,
- inspector/actions are less passive,
- artifacts/blocks participate in real reuse flow.

## Exact changed files

- `apps/web/public/index.html`
- `apps/web/public/main.css`
- `apps/web/public/client.js`
- `apps/web/server.js`
- `lisp/src/runtime-state.lisp`
- `lisp/src/evaluator.lisp`
- `lisp/src/views.lisp`
- `lisp/src/repl.lisp`
- `docs/runbooks/RUNBOOK__TRUERUL__DESKTOP_WORKBENCH_DENSITY_AND_FLOW__v1.md`
- `docs/reports/REPORT__TRUERUL__DESKTOP_WORKBENCH_DENSITY_AND_FLOW__v1.md`

## Package coverage

1. Package A (clean execution)
- runtime default output mode switched to `:clean`
- shell still keeps quick clean/verbose controls + status field
- noisy entity/relation/state registration remains suppressed in clean mode

2. Package B (completion/palette usefulness)
- completion panel added in `Правка / Буфер`
- Russian canonical templates expanded
- quick query insertions for:
  - `(запрос (связь? ...))`
  - `(запрос (сущность? ...))`
  - `(запрос (состояние? ...))`
- `Tab` completion for form head in buffer

3. Package C (schemes)
- concept scheme rendering now clusters:
  - outgoing relations
  - incoming relations
  - related states
  - tensions
  - dichotomies
- repeated lines reduced via dedupe

4. Package D (inspector usefulness)
- inspector actions expanded:
  - insert to buffer
  - run in console
  - open preview
  - save as block

5. Package E (saved blocks/artifacts)
- artifact buckets extended:
  - `tables`
  - `blocks`
- `(сохранить-таблицу ...)` now writes to `tables`
- block save now also writes artifact file into `blocks`
- runtime commands added:
  - `(блоки)`
  - `(выполнить-блок <имя>)`

6. Package F (buffer flow)
- clearer buffer action strip kept and stabilized
- insertion paths from completion/inspector/artifacts unified
- bottom zone now has 3 tabs:
  - shell log
  - buffer preview
  - artifact preview

7. Package G (history/back flow)
- toolbar history shortcut added
- history panel commands now actionable (`run` / `insert`)
- shell back behavior preserved (`pane-back` fallback to `(назад)`)

8. Package H (density polish)
- one more pass on compact spacing/sizing:
  - denser controls, pane paddings, toolbar and bottom tabs
  - less mobile leftover feel
  - old-IDE calm contour preserved

## Verification executed

- `node --check apps/web/public/client.js` passed
- `node --check apps/web/server.js` passed
- Lisp smoke:
  - `(блоки)`
  - `(выполнить-блок demo)` (expected error when absent)
  - `(схема время)` (clustered output visible)
- API smoke:
  - `GET /api/artifacts?bucket=tables` -> `200`
  - `GET /api/artifacts?bucket=blocks` -> `200`
- HTML markers confirmed in served index:
  - `tool-history`
  - `completion-input`
  - `artifact-open-view`
  - `inspector-save-block`
  - bottom tab `artifact`

## Known limits

- completion is lightweight and deterministic (not semantic inference/autocomplete engine)
- block list in shell uses runtime command and artifact flow; no separate dedicated block API surface yet
- settings pane remains honest growth stub (not full configuration subsystem)

