# RUNBOOK — Truerul: console -> nolcli side panel -> local workbench prep (v1)

## Stage 1 — strong console (done baseline)

### What is live now
- Lisp heart entry: `lisp/scripts/run_truerul.sh`
- Web terminal entry: `apps/web/server.js`
- Web health: `GET /health`

### Key commands verified
- Core RU forms: `сущность`, `связь`, `состояние`, `запрос`
- Query heads: `сущность?`, `связь?`, `состояние?`
- Structural views: `вид категории`, `вид напряжения`, `вид дихотомии`, `вид дерево-категорий`, `схема`, `вид схема`
- Console tools: `история`, `назад`, `повторить`, `буфер`, `блок`, `вставить-блок`, `сохранить*`

### Clean-result mode
`режим` now supports output discipline:
- ` (режим :вывод clean)` -> hide noisy registration confirmations
- ` (режим :вывод verbose)` -> show build confirmations
- ` (режим :язык ru|en)` remains supported
- combined form supported: ` (режим :язык ru :вывод clean)`

### Restart web terminal
```bash
cd /srv/truerul
pkill -f 'node apps/web/server.js' || true
tmux has-session -t truerul-web 2>/dev/null && tmux kill-session -t truerul-web || true
tmux new-session -d -s truerul-web 'cd /srv/truerul && TRUERUL_RUNTIME=lisp TRUERUL_WEB_PORT=4173 node apps/web/server.js'
```

### Quick verify
```bash
curl -sS http://127.0.0.1:4173/health
curl -sSI http://127.0.0.1:4173/vendor/xterm/css/xterm.css | head
```

---

## Stage 2 — real adjacent contour beside nolcli

### Bootstrap script
`/srv/truerul/scripts/tmux/truerul_nol_side_panel.sh`

### What it does
- uses existing tmux session (default: `nevis`)
- creates window `TRUERUL-NOL`
- left pane: live `nolcli` (`/srv/WORLD/projects/nevis_console_v0/bin/nol`)
- right pane: Truerul Lisp console (`bash lisp/scripts/run_truerul.sh`)

### Run
```bash
cd /srv/truerul
scripts/tmux/truerul_nol_side_panel.sh nevis
```

### Optional overrides
```bash
TRUERUL_NOL_WINDOW=PAIR \
NOL_ROOT=/srv/WORLD/projects/nevis_console_v0 \
TRUERUL_ROOT=/srv/truerul \
scripts/tmux/truerul_nol_side_panel.sh nevis
```

---

## Stage 3 — local laptop workbench prep over console

### Sync discipline (VPS -> GitHub -> laptop)

On VPS:
```bash
cd /srv/truerul
git add .
git commit -m "truerul: console finish + nol side panel + local workbench prep"
git push
```

On laptop:
```bash
cd ~/path/to/truerul
git pull --ff-only
npm ci
```

### Local run contours (laptop)

Terminal-only heart:
```bash
cd ~/path/to/truerul
bash lisp/scripts/run_truerul.sh
```

Optional local web contour:
```bash
cd ~/path/to/truerul
TRUERUL_RUNTIME=lisp TRUERUL_WEB_PORT=4173 node apps/web/server.js
# open http://127.0.0.1:4173/
```

### Local workbench-prep launcher
`/srv/truerul/scripts/tmux/truerul_local_workbench.sh`

What it creates:
- main pane: live Truerul console
- side pane 1: form buffer scratch shell
- side pane 2: command/snippet palette shell
- side pane 3: artifacts/view watcher

Run:
```bash
cd ~/path/to/truerul
scripts/tmux/truerul_local_workbench.sh truerul-local
```

### Local filesystem hygiene
Ignored in repo:
- `node_modules/`
- `lisp/artifacts/`
- `apps/web/server.pid`
- `apps/web/server-*.pid`
- `apps/web/server*.log`

This keeps local runtime artifacts and process leftovers out of Git.
