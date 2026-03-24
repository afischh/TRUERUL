# SPEC — Truerul .lib architecture, filters, and lightweight assist-layer (v1)

Date: 2026-03-24
Root: `/srv/truerul`

## 1) `.lib` format (v1)

Each `.lib` is a structured executable library module, not a text archive.

Required fields:
- `id`
- `name`
- `family`
- `domain`
- `strictness`
- `logic-mode`
- `ontology-mode`
- `maturity`
- `input-kinds`
- `output-kinds`
- `operators`
- `automata`
- `requires`
- `notes`

Optional fields:
- `cost`
- `path` (runtime indexed metadata)
- `valid-p` (runtime indexed metadata)

## 2) Mandatory first 5 libs

- `logic/classical.lib`
- `logic/fuzzy.lib`
- `logic/paraconsistent.lib`
- `foundations/mltt.lib`
- `foundations/uf.lib`

Each contains:
- base operator signatures,
- input/output kinds,
- minimal automata classifiers,
- applicability filters through domain/logic/ontology/strictness/input/output/cost.

## 3) Filter mechanism as first-class

Filter axes:
- `domain`
- `strictness`
- `logic-mode`
- `ontology-mode`
- `maturity`
- `input-kind`
- `output-kind`
- `cost`

Runtime commands:
- `(lib-индекс)` — reindex libs
- `(lib-список <filters...>)`
- `(lib-подобрать <filters...>)`

Routing uses filtered candidates + score by filter-fit + maturity/cost profile.

## 4) Assist-layer (lightweight, non-sovereign)

Roles:
- `parse-assist`
- `routing-assist`
- `hypothesis-draft`
- `normalization-suggestions`

Strict limits:
- no final proof authority,
- no final truth authority,
- no autonomous ontology construction.

v1 contour:
- heuristic assist always available,
- optional command-based LLM co-processor via `TRUERUL_ASSIST_CMD`,
- architecture is model-agnostic (provider can be replaced without touching core pipeline).

## 5) Recommended minimal open-source model contour

Primary lightweight route:
- `qwen2.5:1.5b-instruct` via local Ollama (or equivalent small local model)

Why:
- low memory footprint,
- practical response speed on VPS/laptop,
- sufficient for parse/routing/hypothesis drafts.

Integration model:
- model output is advisory only,
- dispatcher + .lib filters + automata keep decision authority.

## 6) Pipeline “operator speech -> forms -> .lib -> classified output”

Command:
- `(оператор "<input>" <optional-filters...>)`

Steps:
1. operator input
2. parse-assist + normalization suggestions
3. normalized Truerul-form hints
4. `.lib` routing through filters
5. library automata classification
6. classified output

Class set:
- `истина`
- `ложь`
- `неопределённо`
- `возможно`
- `возможно-в-режиме-X`
- `несовместимо-с-онтологией`
- `требует-новой-гипотезы`

## 7) Voice linkage (v1)

- `синтез` -> hypothesis-draft default tendency
- `сборка` -> normalization/construction tendency
- `предел` -> diagnosis/classification tendency

Voice affects assist profile, not core truth sovereignty.

