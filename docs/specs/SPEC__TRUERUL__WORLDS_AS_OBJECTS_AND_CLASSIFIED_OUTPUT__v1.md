# SPEC — Truerul worlds as objects and classified output (v1)

Date: 2026-03-25
Root: `/srv/truerul`

## 1) World object model

World is a first-class runtime object with explicit fields:
- `:name`
- `:entities`
- `:relations`
- `:states`
- `:logic-mode`
- `:ontology-mode`
- `:evaluation-mode`
- `:source`
- `:created-at`

Runtime keeps a world registry + active world:
- `runtime-worlds`
- `runtime-active-world`

Default world is seeded on runtime bootstrap as `основной`.

## 2) Russian-first world operations

Canonical RU-first forms:
- `(мир <имя>)` — snapshot current runtime into named world-object
- `(миры)` — list worlds and active world
- `(мир-показать <имя>)` — inspect world summary
- `(мир-активировать <имя>)` — load world into runtime
- `(сравнить-миры A B)` / alias `(миры-сравнить A B)`
- `(объединить-миры A B :в C)` / alias `(миры-объединить A B :в C)`
- `(вычесть-мир A B :в C)` / alias `(миры-вычесть A B :в C)`

English compatibility aliases preserved:
- `world`, `worlds`, `world-show`, `world-activate`, `compare-worlds`, `merge-worlds`, `subtract-world`.

## 3) Classified output vocabulary (v1)

Base classes:
- `истина`
- `ложь`
- `неопределённо`
- `возможно`
- `возможно-в-режиме-X`
- `несовместимо-с-онтологией`
- `требует-новой-гипотезы`
- `диагноз`
- `конструкция`
- `кандидат`

Classification is returned as structured result with optional metadata:
- `logic-mode`
- `ontology-mode`
- `evaluation-mode`
- `world-name`
- `report-lines`

## 4) World operation semantics (v1)

Compare (`сравнить-миры`):
- computes shared / only-A / only-B / conflicts for entities/relations/states
- yields inspectable report and classifies result

Merge (`объединить-миры`):
- unions structures into target world
- tracks entity/state conflicts
- in tolerant logic modes (`paraconsistent`, `many-valued`, `fuzzy`, `dynamic-epistemic`) conflicts can be accepted with mode-qualified class

Subtract (`вычесть-мир`):
- subtracts B structures from A into target world
- returns removal counters + resulting world

## 5) Voice linkage

Class interpretation is voice-aware:
- `сборка` -> construction-oriented classes (`конструкция`)
- `предел` -> diagnosis-oriented classes (`диагноз`, incompatibility attention)
- `синтез` -> candidate/possibility tendency

## 6) Mode hooks for future logic routing

`(режим ...)` now supports:
- `:логика` / `:logic`
- `:онтология` / `:ontology`
- `:оценка` / `:evaluation`

These are persisted into world snapshots and surfaced in classified output.
This keeps compatibility with upcoming `.lib` filter/dispatcher routing.

## 7) RU/EN surface law

- RU remains default visible surface (`runtime-lang = :ru`)
- EN remains switchable compatibility mode via `(режим :язык en)`
- help and command palette keep RU-first canonical forms, EN aliases are secondary
