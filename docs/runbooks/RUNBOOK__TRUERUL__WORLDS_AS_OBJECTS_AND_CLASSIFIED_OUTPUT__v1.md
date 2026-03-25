# RUNBOOK — Truerul worlds as objects and classified output (v1)

Date: 2026-03-25
Root: `/srv/truerul`

## 1) Restart web runtime (if needed)

```bash
cd /srv/truerul
pkill -f 'node apps/web/server.js' || true
tmux has-session -t truerul-web 2>/dev/null && tmux kill-session -t truerul-web || true
tmux new-session -d -s truerul-web 'cd /srv/truerul && TRUERUL_RUNTIME=lisp TRUERUL_WEB_PORT=4173 node apps/web/server.js'
```

## 2) Core world-object smoke

```bash
cd /srv/truerul
printf '(режим)\n(сущность мама :тип агент)\n(сущность город :тип место)\n(связь мама живёт-в город)\n(состояние мама адаптация)\n(мир базовый)\n(миры)\n(мир-показать базовый)\n' | timeout 40s bash lisp/scripts/run_truerul.sh
```

Expected:
- world `базовый` appears in `(миры)`
- `(мир-показать базовый)` prints summary with entities/relations/states and mode fields.

## 3) Compare / merge / subtract smoke

```bash
cd /srv/truerul
printf '(мир A)\n(сущность x :тип агент)\n(мир B)\n(сравнить-миры A B)\n(объединить-миры A B :в C)\n(вычесть-мир C A :в D)\n' | timeout 40s bash lisp/scripts/run_truerul.sh
```

Expected:
- compare returns `[классификация]` with report
- merge creates world `C` and returns classification + report
- subtract creates world `D` and returns classification + report.

## 4) Evaluation mode hooks smoke

```bash
cd /srv/truerul
printf '(режим :логика paraconsistent :онтология type :оценка heuristic)\n(режим)\n' | timeout 30s bash lisp/scripts/run_truerul.sh
```

Expected:
- mode update acknowledged
- `(режим)` shows `логика: paraconsistent`, `онтология: type`, `оценка: heuristic`.

## 5) Classified output catalog

```bash
cd /srv/truerul
printf '(классы-вывода)\n' | timeout 30s bash lisp/scripts/run_truerul.sh
```

Expected:
- shows base class vocabulary and voice linkage section.

## 6) Web surface markers

```bash
cd /srv/truerul
curl -sS http://127.0.0.1:4173/ | rg -n 'мир-показать|сравнить-миры|классы-вывода|data-command="\(миры\)"'
curl -sS http://127.0.0.1:4173/client.js | rg -n 'сравнить-миры|мир-показать|классы-вывода|:логика'
```
