# SPEC — Truerul — mobile terminal surface v0

Status: DRAFT
Language: RU
Scope: первая реальная terminal-surface версия маленького REPL-языка для телефона

## 0. Короткая формула

Построить **настоящую веб-консоль для телефона**,
в которой живёт маленький REPL-язык `Truerul`.

Это terminal surface с:
- ANSI-цветом
- prompt-ритмом
- history
- scrollback
- PTY-контуром
- живым REPL-опытом на узком экране
- canonical quoted lispy surface
- возможностью переключения surface vocabulary между RU и EN

Это должен быть не музейный терминал,
а честный рабочий прибор.
Если он при этом окажется красив,
тем лучше для него,
но нельзя позволять красоте разжаловать смысл до должности подсветки.

---

## 1. Объект строительства

Строится:
- mobile-first web terminal
- xterm-like terminal surface
- websocket attach
- PTY-backed REPL session
- минимальный ANSI-styled output
- quoted lispy forms as primary v0 interaction
- later human surface support beside the quoted mode

Сейчас не строится:
- GUI-панели вокруг терминала
- dashboard
- full editor
- multiplayer
- тяжёлая persistence layer

---

## 2. Архитектурная формула

### Frontend
- full-screen terminal surface
- one viewport
- minimal action strip
- mobile keyboard-aware layout

### Backend
- websocket bridge
- one PTY per session
- REPL process inside PTY
- session lifecycle control

### REPL process
- line input
- parse/execute
- held forms in memory
- log output
- ANSI output formatter
- surface vocabulary switch RU/EN

### Strong formula
**browser terminal -> websocket -> PTY -> truerul repl**

---

## 3. Terminal law

### Must be true
- terminal is primary object
- prompt is real
- output is ANSI text, not HTML imitation
- resize is real
- history works
- clear works
- interrupt policy is defined

### Must not happen
- fake terminal made of div blocks
- dashboard inflation
- chat-bubble interaction
- many floating panels on phone

---

## 4. Mobile surface v0

### 4.1 Layout

One-screen structure:

1. **Header strip**
   - title: `TRUERUL`
   - session mark
   - tiny mode indicator: `RU` / `EN`
   - optional tiny status indicator

2. **Main terminal viewport**
   - terminal occupies almost all screen
   - scrollback visible
   - input cursor always clear

3. **Action strip**
   - `query`
   - `log`
   - `step`
   - `clear`
   - later optional `RU/EN`

### 4.2 Keyboard law
- viewport must resize when mobile keyboard opens
- terminal must remain focused after shortcuts
- no hidden input box outside the terminal

### 4.3 Width discipline
- narrow-screen safe formatting
- no dependence on wide layouts
- forms should wrap acceptably

---

## 5. ANSI palette v0

Use restrained palette only.

### Semantic colors
- **cold cyan/azure** — headers, form kinds, structural labels
- **ash gray** — ordinary form text
- **dim yellow** — warnings / unresolved / notable transitions
- **soft red** — failure / contradiction / parse or eval rupture
- **copper/rust** — tension, charged state, strange emphasis
- **rare muted green** — accepted stable operation

### Output classes
- prompt
- ok/system
- quoted form echo
- query result
- warning
- error
- section header
- muted metadata

### Rule
No rainbow terminal.
No gamer RGB fever.
Needed feeling:
**old cybernetic instrument for handling forms**.

---

## 6. Primary interaction mode v0

Primary mode:
**quoted lispy surface**

Examples:

```text
(entity эвридика-9 :kind автономный-андроид)
(relation эвридика-9 ищет астрей)
(state эвридика-9 сомнение)
(query (relation? эвридика-9 ищет X))
```

Human surface may later coexist,
but v0 does not depend on it.

### Runtime commands
- `(query ...)`
- `(log)`
- `(step)`
- `(view ...)`
- `(quote ...)`
- `(eval ...)`
- `(help)`
- `(clear)` or terminal clear mapping

---

## 7. REPL experience law

Every command must produce one of:
- clear confirmation
- typed error
- query result
- log output
- form echo or view output

Never silent success.
Never vague parser failure.

### Good interaction tone
- concise
- slightly ceremonial
- form-aware
- dryly witty when useful

Example:

```text
TRUERUL :: RU :: цикл 00
> (entity эвридика-9 :kind автономный-андроид)
[ok] entity registered: эвридика-9 :: kind автономный-андроид
```

```text
> (query (entity? X :kind автономный-андроид))
[query]
X = эвридика-9
```

```text
> (quote (state эвридика-9 сомнение))
[form]
(state эвридика-9 сомнение)
```

---

## 8. PTY/session model v0

### Session truth
- one browser session attaches to one PTY-backed repl session
- one session holds one active form-space
- reconnect policy may be added later

### Minimal controls
- create session
- attach session
- terminate session
- clear active held forms if desired later

### Strong distinction
Browser tab is not the metaphysical owner of meaning,
though in v0 it may temporarily serve as the practical session anchor,
как это и бывает с множеством временных решений,
которые потом внезапно начинают требовать себе памятник и отдельный раздел в истории проекта.

---

## 9. First implementation phases

## Phase 1 — terminal body exists
Deliverable:
- web page with real terminal surface
- backend websocket
- PTY session startup
- dummy echo REPL running inside PTY

DoD:
- terminal opens on phone
- text input works
- ANSI colors visible
- action strip sends commands

## Phase 2 — quoted language kernel lives
Deliverable:
- minimal parser for quoted forms
- held forms in memory
- query/log output

DoD:
- user can register entities/relations/states
- ask a simple query
- see readable output

## Phase 3 — rule and reflection foothold
Deliverable:
- `rule`
- `quote`
- `eval`
- maybe first `view`

DoD:
- canonical reflective micro-session works

## Phase 4 — mobile polish
Deliverable:
- keyboard-safe resize
- better line wrapping
- persistent session feel
- PWA shell preparation

DoD:
- daily usable from phone

---

## 10. First canonical demo session

```text
(entity эвридика-9 :kind автономный-андроид)
(entity астрей :kind бог)
(relation эвридика-9 ищет астрей)
(state эвридика-9 сомнение)
(query (relation? эвридика-9 ищет X))
(log)
```

Expected truth:
- forms load cleanly
- query produces binding output
- log shows the sequence
- terminal output feels precise and alive

---

## 11. Immediate next build move

Build **Phase 1 only** first.

Exact target:
- one mobile web page
- one terminal viewport
- one backend route for websocket
- one PTY session
- one dummy REPL process that prints colored prompt and echoes input

Only after that:
- quoted parser
- held form space
- query output
- rule/quote/eval

---

## 12. Canonical closing sentence

Сначала нужно родить не все режимы языка,
а его телесную консольную оболочку:
узкий,
живой,
цветной терминал на телефоне,
в котором quoted forms уже можно произносить вслух,
и они не падают на пол,
как плохо собранные детали от метафизического шкафа.
