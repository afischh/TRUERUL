# SPEC — Truerul — core language v0

Status: DRAFT
Language: RU
Scope: language-first core for a small lisp-like homoiconic REPL language with RU/EN surface switching

## 0. Short formula

**Truerul** — маленький лиспоподобный homoiconic REPL-язык
для размышления вместе с формами,
а не только для описания фиксированных наборов объектов.

Он должен уметь работать с:
- сущностями
- связями
- состояниями
- правилами
- вопросами
- представлениями
- quoted forms
- странной математикой
- экспериментальными геометриями
- невозможными онтологиями

Мир здесь возможен,
но не обязателен.
Главное — форма,
её вызывание,
её рассмотрение,
её преобразование,
её исполнение.

---

## 1. Design law

Language-first.
Not lore-first.
Not UI-first.

### Strong law
Сначала Truerul должен научиться говорить о формах.
Потом — о более сложных порядках вещей.

---

## 2. Canonical modes

## Mode A — quoted lispy surface
This is the canonical v0 mode.

Examples:

```text
(entity эвридика-9 :kind автономный-андроид)
(relation эвридика-9 ищет астрей)
(state эвридика-9 сомнение)
(query (relation? эвридика-9 ищет X))
```

## Mode B — human surface
This is a supported convenience layer.

Examples:

```text
сущность эвридика-9 :тип автономный-андроид
связь эвридика-9 ищет астрей
состояние эвридика-9 сомнение
вопрос (связь? эвридика-9 ищет X)
```

### Rule
v0 may begin directly from quoted lispy surface.
Human surface may grow beside it,
not above it.

---

## 3. Surface language switching

Surface should be switchable between RU and EN.

### RU examples
```text
(entity эвридика-9 :kind автономный-андроид)
(rule R1 :if (relation эвридика-9 ищет астрей)
          :then (state эвридика-9 напряжение))
```

### EN examples
```text
(entity eurydice-9 :kind autonomous-android)
(rule R1 :if (relation eurydice-9 seeks astraeus)
          :then (state eurydice-9 tension))
```

### Law
Surface switching must not change core meaning.
It changes readable vocabulary,
not the internal form discipline.

---

## 4. Core objects

## Form
Any quoted or executable form.

## Entity
- id
- kind
- attrs

## Relation
- subject
- predicate
- object
- attrs optional later

## StateMark
- target
- state
- attrs optional later

## Rule
- id optional in v0
- condition
- consequence

## Query
- pattern
- bindings
- mode later

## View
- named rendering or perspective over current held forms

## Log
- event entries
- evaluation notes
- derivation notes later

## Step
- optional temporal or derivational advancement

## World
- one possible aggregation mode,
  not the metaphysical center of the language

---

## 5. Minimal canonical forms v0

```text
(entity <id> :kind <kind> ...)
(relation <subject> <predicate> <object> ...)
(state <target> <state> ...)
(rule <id>? :if <condition> :then <consequence>)
(query <pattern>)
(view <name>?)
(log)
(step)
(quote <form>)
(eval <form>)
```

### Required note
`quote` and `eval` may be tiny in v0,
but the language must be designed from the start
so that forms can become objects of reflection.

---

## 6. Homoiconic discipline

This is not decorative Lispy flavor.
This is structural law.

The language should later support:
- seeing forms as data
- storing forms
- quoting forms
- transforming forms
- re-evaluating forms
- discussing forms on the surface of the language itself

### Why
Without this,
Truerul becomes merely a DSL with parentheses.
With this,
it can grow into a real language of reflection.

---

## 7. Queries and reflection

The language must not stop at assertions.
It must also ask.

### Query examples
```text
(query (relation? X ищет Y))
(query (state? Z сомнение))
(query (entity? X :kind бог))
```

### Reflective examples later
```text
(quote (entity астрей :kind бог))
(eval (quote (state астрей молчание)))
```

---

## 8. Strange mathematics and geometry

Truerul should allow forms that are not only narrative or worldly.

Examples of later thematic use:
- impossible entities
- multi-perspectival objects
- soft or paraconsistent rules
- topological or Obj0-like geometric relations
- symbolic or experimental mathematics
- relations that are not easily reduced to naive simulation

### Law
Do not trap the language in one narrow representational habit.
Let one mode be only one mode,
not the prison of the core.

---

## 9. Internal architecture expectation

### packages/core-language
Should hold:
- AST
- form kinds
- evaluator
- entity/relation/state/rule/query model
- log/step mechanics

### packages/surface
Should hold:
- RU/EN vocabulary maps
- reader
- printer
- quoted lispy surface parsing/printing
- human surface parsing/printing later

### apps/web
Should hold:
- terminal body
- prompt UX
- session surface
- ANSI rendering

---

## 10. v0 milestone

v0 is successful if in the terminal one can:

```text
(entity эвридика-9 :kind автономный-андроид)
(entity астрей :kind бог)
(relation эвридика-9 ищет астрей)
(state эвридика-9 сомнение)
(query (relation? эвридика-9 ищет X))
(log)
```

and receive:
- typed confirmations
- meaningful query output
- readable log output
- quoted form visibility

---

## 11. Canonical closing sentence

Truerul должен сначала стать языком,
который умеет держать формы перед собой,
говорить о них,
запрашивать их,
преобразовывать их,
и лишь затем,
если пожелает,
разрешить им строить более сложные порядки.
