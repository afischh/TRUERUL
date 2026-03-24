# RUNBOOK — Truerul desktop workbench density and flow (v1)

Date: 2026-03-24
Root: `/srv/truerul`

## 1) Restart contour on VPS

```bash
cd /srv/truerul
pkill -f 'node apps/web/server.js' || true
tmux has-session -t truerul-web 2>/dev/null && tmux kill-session -t truerul-web || true
tmux new-session -d -s truerul-web 'cd /srv/truerul && TRUERUL_RUNTIME=lisp TRUERUL_WEB_PORT=4173 node apps/web/server.js'
```

Open:
- `http://127.0.0.1:4173/`
- external: `http://<host>:4173/?v=workbench-density-v1`

Hard refresh:
- desktop: `Ctrl+Shift+R`
- mobile: clear site data for host or change `?v=` token.

## 2) Quick verification checklist

```bash
curl -sS http://127.0.0.1:4173/health
curl -sS http://127.0.0.1:4173/ | rg -n 'tool-history|completion-input|artifact-open-view|inspector-save-block|data-bottom-pane="artifact"'
curl -sS 'http://127.0.0.1:4173/api/artifacts?bucket=tables' | rg '"ok"|"bucket"'
curl -sS 'http://127.0.0.1:4173/api/artifacts?bucket=blocks' | rg '"ok"|"bucket"'
```

## 3) Runtime checks (Lisp)

```bash
cd /srv/truerul
printf '(режим :вывод clean)\n(блоки)\n(схема время)\n' | timeout 20s bash lisp/scripts/run_truerul.sh
```

Expected:
- banner starts with `:: RU :: CLEAN`
- `(блоки)` works
- `(схема <понятие>)` has clustered readable sections.

## 4) Operator flow (v1.5)

1. Keep output in `clean` for normal work (`verbose` only for diagnostics).
2. Use right-pane completion block and `Tab` completion in buffer.
3. Use quick query insertions for `связь?` / `сущность?` / `состояние?`.
4. Save reusable forms as blocks (`Сохранить блок`), inspect through `blocks` bucket.
5. Reuse history entries via `run` / `insert` actions in panel `История`.
6. Use bottom tabs for `Вывод shell` / `Буфер preview` / `Artifact preview`.

## 5) New practical commands

- `(блоки)` — list known blocks
- `(выполнить-блок <имя>)` — execute saved block
- `(сохранить-таблицу <имя>)` — writes into artifact bucket `tables`
- `(режим :вывод clean|verbose)` — visible in toolbar + status line

## 6) Laptop downstream

On VPS:

```bash
cd /srv/truerul
git add apps/web/public/index.html apps/web/public/main.css apps/web/public/client.js apps/web/server.js lisp/src/runtime-state.lisp lisp/src/evaluator.lisp lisp/src/views.lisp lisp/src/repl.lisp docs/runbooks/RUNBOOK__TRUERUL__DESKTOP_WORKBENCH_DENSITY_AND_FLOW__v1.md docs/reports/REPORT__TRUERUL__DESKTOP_WORKBENCH_DENSITY_AND_FLOW__v1.md
git commit -m "Truerul: workbench v1.5 density and flow improvements"
git push
```

On laptop:

```bash
cd ~/path/to/truerul
git pull --ff-only
npm ci
TRUERUL_RUNTIME=lisp TRUERUL_WEB_PORT=4173 node apps/web/server.js
```

Open:
- `http://127.0.0.1:4173/?v=workbench-density-v1`

