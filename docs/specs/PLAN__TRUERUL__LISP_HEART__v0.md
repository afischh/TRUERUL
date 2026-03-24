# PLAN — Truerul — Lisp heart v0

Status: ACTIVE
Language: RU
Scope: перенос language heart Truerul из временного JS-prototype в Lisp runtime при сохранении уже живого terminal body

## 0. Короткая формула

У Truerul уже есть terminal body.
Теперь ему нужно дать **Lisp heart**.

Принятое решение:
- web terminal остаётся на текущем JS/PTy/websocket-контуре
- language runtime начинает рождаться на Lisp уже сейчас
- JS-runtime больше не выращивается как долгосрочное сердце языка

Коротко:
**JS = skin and wire**
**Lisp = language heart**

---

## 1. Why now

Текущий момент правильный,
потому что:
- терминал уже реально живёт
- quoted surface уже дышит
- формы уже можно вводить и видеть
- если продолжать наращивать semantics в JS,
  Truerul начнёт закрепляться как DSL в чужом теле

Это не трагедия,
но это именно тот тип вежливой архитектурной ошибки,
который потом годами представляется «временным решением»
и требует к себе всё большего уважения.

Поэтому перенос сердца надо начинать сейчас,
пока у проекта уже есть форма,
но ещё нет лишней массы.

---

## 2. Accepted architecture after decision

### What remains in JS
- `apps/web`
- terminal surface
- websocket bridge
- PTY attach
- mobile shell behavior
- minimal browser controls

### What moves to Lisp
- quoted reader / parser
- internal form representation
- entity / relation / state core
- query core
- log / step
- later rule / quote / eval / view / transforms

### Strong seam
Browser terminal must speak to a Lisp process,
not to a growing JS semantics layer.

---

## 3. Growth law

Do not migrate “everything at once”.
Do not continue to deepen JS core either.

Correct motion:
1. freeze JS runtime as temporary prototype
2. create Lisp runtime beside it
3. attach PTY to Lisp runtime path
4. reach parity for minimal quoted core
5. continue all deeper language growth in Lisp only

---

## 4. What is frozen in JS

The current JS core may remain only as:
- temporary demonstrator
- shape reference
- terminal-body bootstrap companion

It must **not** become the place where we implement:
- rich rules
- serious reflection
- soft logic machinery
- deep query semantics
- strange mathematics core
- geometry operators

That growth belongs to Lisp.

---

## 5. First Lisp milestone — L1

The first Lisp runtime milestone must be very small and very real.

### L1 must support
```text
(entity <id> :kind <kind>)
(relation <subject> <predicate> <object>)
(state <target> <state>)
(query <pattern>)
(log)
(step)
```

### L1 truth
- forms are parsed in Lisp
- held forms live in Lisp
- query is answered in Lisp
- log is stored in Lisp
- terminal still talks through PTY

This is enough.
Nothing grander is required for L1.

---

## 6. Repository implication

A new root should appear for the runtime heart.

Recommended position:
- `/srv/truerul/lisp/`

Suggested early structure:

```text
lisp/
  README.md
  truerul-runtime.asd
  src/
    package.lisp
    reader.lisp
    runtime_state.lisp
    evaluator.lisp
    query.lisp
    repl.lisp
  scripts/
    run_truerul.sh
```

### Why separate root
Because this is not a tiny helper.
This is the heart line.
It deserves clear visibility.

---

## 7. Interface law between terminal and Lisp

The terminal should not know deep language semantics.
It only needs:
- process attach
- input
- output
- resize
- session relation

The Lisp process should own:
- form reading
- evaluation
- held state
- query results
- log text
- language errors

---

## 8. Immediate implementation order

### Phase A — freeze JS runtime
- leave current JS prototype intact
- stop deepening it

### Phase B — create Lisp runtime skeleton
- create `lisp/`
- package
- runtime state
- tiny REPL loop

### Phase C — first executable path
- one script launches Lisp runtime from PTY
- terminal can attach to it manually

### Phase D — minimal parity
- `entity`
- `relation`
- `state`
- `query`
- `log`
- `step`

### Phase E — switch primary runtime
- web terminal default path points to Lisp runtime
- JS prototype becomes fallback only

---

## 9. What comes only after L1

Only after L1 parity may we deepen:
- `rule`
- `quote`
- `eval`
- `view`
- reflective transforms
- soft and non-classical logic experiments
- strange mathematics forms
- Obj0-geometry operators

Not earlier.
Because the language must first prove
that its minimal bones really stand in Lisp.

---

## 10. Canonical decision

Accepted:
**Truerul runtime on Lisp is not a late dream. It begins now.**

More precise form:
**terminal body was allowed to be born on JS. language heart must now be born on Lisp.**

---

## 11. Canonical closing sentence

Truerul уже обрёл экран,
курсор
и первую речь.
Теперь ему нужно обрести более глубокую кровь:
не декоративно-лисповую,
а настоящую Lisp-кровь,
чтобы формы не только выглядели правильно,
но и жили в правильном веществе.
