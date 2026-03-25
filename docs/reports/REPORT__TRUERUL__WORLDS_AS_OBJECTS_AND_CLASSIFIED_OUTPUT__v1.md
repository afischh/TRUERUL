# REPORT — Truerul worlds as objects and classified output (v1)

Date: 2026-03-25
Repo: `/srv/truerul`

## Summary

Implemented first working contour where:
- worlds are explicit runtime objects,
- compare/merge/subtract are executable world operations,
- output is classified with mode-aware and voice-aware semantics,
- RU-first surface remains canonical with EN aliases preserved.

## Exact changed files

- `lisp/src/runtime-state.lisp`
- `lisp/src/worlds.lisp`
- `lisp/src/evaluator.lisp`
- `lisp/src/repl.lisp`
- `lisp/truerul-runtime.asd`
- `apps/web/public/index.html`
- `apps/web/public/client.js`
- `docs/specs/SPEC__TRUERUL__WORLDS_AS_OBJECTS_AND_CLASSIFIED_OUTPUT__v1.md`
- `docs/runbooks/RUNBOOK__TRUERUL__WORLDS_AS_OBJECTS_AND_CLASSIFIED_OUTPUT__v1.md`
- `docs/reports/REPORT__TRUERUL__WORLDS_AS_OBJECTS_AND_CLASSIFIED_OUTPUT__v1.md`

## What is now working

1. World-object runtime line:
- default world `основной` on bootstrap,
- world registry in runtime,
- active world tracking.

2. RU-first world forms:
- `(мир <имя>)`
- `(миры)`
- `(мир-показать <имя>)`
- `(мир-активировать <имя>)`
- `(сравнить-миры A B)`
- `(объединить-миры A B :в C)`
- `(вычесть-мир A B :в C)`

3. Classified output contour:
- classes: `истина`, `ложь`, `неопределённо`, `возможно`, `возможно-в-режиме-X`, `несовместимо-с-онтологией`, `требует-новой-гипотезы`, `диагноз`, `конструкция`, `кандидат`
- result payload now includes optional `logic-mode`, `ontology-mode`, `evaluation-mode`, `world-name`, `report-lines`.

4. Mode hooks in `(режим ...)`:
- `:логика` / `:logic`
- `:онтология` / `:ontology`
- `:оценка` / `:evaluation`

5. Workbench/web reflection:
- world commands added to side panel and palette,
- quick actions for `(миры)` and `(классы-вывода)`,
- mode template in client completions.

6. Help/log visibility:
- updated REPL help for worlds + extended mode args,
- world operations are visible in runtime log rendering.

## Verification (facts)

Runtime smoke command executed:

```bash
cd /srv/truerul
timeout 90s bash lisp/scripts/run_truerul.sh <<'SMOKE'
(режим)
(сущность мама :тип агент)
(сущность город :тип место)
(связь мама живёт-в город)
(состояние мама адаптация)
(мир базовый)
(миры)
(сравнить-миры основной базовый)
(объединить-миры основной базовый :в объединенный)
(вычесть-мир объединенный базовый :в остаток)
(классы-вывода)
(режим :логика paraconsistent :онтология type :оценка heuristic)
(режим)
SMOKE
```

Observed:
- compile/load successful,
- `мир` snapshots appear in world list,
- compare returns classified `истина` with report,
- merge returns classified `конструкция` with target world,
- subtract returns classified `ложь` for empty remainder,
- `классы-вывода` returns class catalog,
- mode changes are applied and visible in `(режим)`.

Web JS syntax check executed:

```bash
cd /srv/truerul
node --check apps/web/public/client.js
```

Result: pass.

## Honest limits

- This is v1 operational contour, not full formal theorem engine.
- World operations are deterministic structural transforms/classifications, not complete logic proof calculus.
- `.lib` routing integration is prepared via mode/result fields and not replaced by this layer.
