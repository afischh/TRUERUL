# RUNBOOK — Truerul language stratification and three voices (v1)

Date: 2026-03-24
Root: `/srv/truerul`

## 1) Restart web contour

```bash
cd /srv/truerul
pkill -f 'node apps/web/server.js' || true
tmux has-session -t truerul-web 2>/dev/null && tmux kill-session -t truerul-web || true
tmux new-session -d -s truerul-web 'cd /srv/truerul && TRUERUL_RUNTIME=lisp TRUERUL_WEB_PORT=4173 node apps/web/server.js'
```

Open:
- `http://127.0.0.1:4173/?v=lang-strata-v1`

## 2) Runtime smoke for strata + voices

```bash
cd /srv/truerul
printf '(слои)\n(ритм)\n(голоса)\n(режим :голос предел)\n(применить-голос предел (схема время))\n(гипотеза h1 (связь субъект проверяет границы))\n(вывод)\n' | timeout 30s bash lisp/scripts/run_truerul.sh
```

Expected:
- banner shows `voice ...`
- strata view appears
- voices listed and configurable
- heuristic output appears via active voice.

## 3) Useful command contour

- `(слои)` — language families map
- `(ритм)` — canonical user flow
- `(канон)` — cleanup/canon direction
- `(голоса)` — list voices
- `(голос <имя>)` — inspect one voice
- `(голос <имя> :фокус ... :тенденции (...) :проверки (...) :ключи (...))` — update traits
- `(режим :голос <имя>)` — set active voice
- `(применить-голос <имя> <форма|тема>)` — voice pass
- `(гипотеза ...)`, `(спор ...)`, `(заметка ...)`, `(вывод ...)` — heuristic contour

## 4) Web checks for shell reflection

```bash
curl -sS http://127.0.0.1:4173/ | rg -n 'Голоса|Шаблоны форм по стратам|status-voice|data-command="\\(слои\\)"'
curl -sS http://127.0.0.1:4173/client.js | rg -n 'setVoiceStatus|применить-голос|режим :голос'
```

## 5) Commit/push discipline

```bash
cd /srv/truerul
git add lisp/src/runtime-state.lisp lisp/src/evaluator.lisp lisp/src/repl.lisp apps/web/public/index.html apps/web/public/main.css apps/web/public/client.js docs/specs/SPEC__TRUERUL__LANGUAGE_STRATIFICATION_AND_THREE_VOICES__v1.md docs/notes/NOTE__TRUERUL__COMMAND_SURFACE_CANON_AND_DEPRECATION__v1.md docs/runbooks/RUNBOOK__TRUERUL__LANGUAGE_STRATIFICATION_AND_THREE_VOICES__v1.md docs/reports/REPORT__TRUERUL__LANGUAGE_STRATIFICATION_AND_THREE_VOICES__v1.md
git commit -m "Truerul: language stratification and three voices contour"
git push
```

