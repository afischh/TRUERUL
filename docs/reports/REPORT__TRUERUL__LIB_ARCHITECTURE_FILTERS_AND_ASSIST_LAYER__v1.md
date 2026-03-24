# REPORT — Truerul .lib architecture, filters, and assist-layer (v1)

Date: 2026-03-24
Repo: `/srv/truerul`

## Summary

Implemented first working contour of:
- `.lib` registry/indexing,
- filter-first routing,
- lightweight assist-layer,
- operator pipeline to classified output.

LLM is integrated as optional co-processor, not truth core.

## Exact changed files

- `lisp/src/runtime-state.lisp`
- `lisp/src/lib-layer.lisp`
- `lisp/src/evaluator.lisp`
- `lisp/src/repl.lisp`
- `lisp/truerul-runtime.asd`
- `lisp/libs/logic/classical.lib`
- `lisp/libs/logic/fuzzy.lib`
- `lisp/libs/logic/paraconsistent.lib`
- `lisp/libs/foundations/mltt.lib`
- `lisp/libs/foundations/uf.lib`
- `apps/web/public/index.html`
- `apps/web/public/client.js`
- `scripts/assist/truerul_assist_local.sh`
- `docs/specs/SPEC__TRUERUL__LIB_ARCHITECTURE_FILTERS_AND_ASSIST_LAYER__v1.md`
- `docs/runbooks/RUNBOOK__TRUERUL__LIB_ARCHITECTURE_FILTERS_AND_ASSIST_LAYER__v1.md`
- `docs/reports/REPORT__TRUERUL__LIB_ARCHITECTURE_FILTERS_AND_ASSIST_LAYER__v1.md`

## What is now working

1. `.lib` index/registry:
- `(lib-индекс)`
- `(lib-список <filters...>)`
- `(lib-подобрать <filters...>)`

2. Filter axes in routing:
- `domain`, `strictness`, `logic-mode`, `ontology-mode`, `maturity`, `input-kind`, `output-kind`, `cost`

3. Mandatory first 5 libs loaded:
- `logic.classical`
- `logic.fuzzy`
- `logic.paraconsistent`
- `foundations.mltt`
- `foundations.uf`

4. Assist-layer:
- `(ассист "<input>" :role parse-assist)`
- heuristic provider always active
- optional external lightweight model via `TRUERUL_ASSIST_CMD`
- guarded activation (`TRUERUL_ASSIST_USE_OLLAMA=1`) to avoid accidental model pulls

5. Operator pipeline:
- `(оператор "<input>" <filters...>)`
- path: speech -> assist/normalize -> filter-route -> `.lib` stack -> classification

6. Classified output labels in runtime:
- `истина`
- `ложь`
- `неопределённо`
- `возможно`
- `возможно-в-режиме-X`
- `несовместимо-с-онтологией`
- `требует-новой-гипотезы`

## Voice linkage (v1)

- `синтез` -> hypothesis-draft tendency
- `сборка` -> normalization/construction tendency
- `предел` -> diagnosis/classification tendency

## Verified facts

- `.lib` index loads 5 modules
- filter routing returns scored candidates
- operator pipeline returns classification + selected lib + route trace
- web shell exposes `.lib` commands in left pane/help/palette
- `node --check apps/web/public/client.js` passes

## Honest limits

- assist-layer LLM is optional and advisory, not mandatory runtime dependency
- classification automata are minimal v1 heuristics, not full theorem prover
- NL parsing is controlled contour, not general language understanding
