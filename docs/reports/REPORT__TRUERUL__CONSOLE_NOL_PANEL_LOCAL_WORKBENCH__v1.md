# REPORT — Truerul console -> nolcli panel -> local workbench prep (v1)

Date: 2026-03-24
Project root: `/srv/truerul`

## Summary

Three-stage line is now materially implemented:
1. Console strengthened and Russian-first layer extended, including clean/result output mode.
2. Real adjacent runtime contour beside nolcli is bootstrapped via tmux script.
3. Local laptop workbench-prep contour is bootstrapped via tmux script + sync/run discipline docs.

## Stage 1 — implemented

### Terminal/web fixes
- `apps/web/server.js`
  - fixed xterm CSS serving path (`/vendor/xterm/css/xterm.css`)
- `apps/web/public/index.html`
  - switched stylesheet path to working xterm CSS route

### Runtime language/console strengthening
- `lisp/src/runtime-state.lisp`
  - added `output-mode` state (`:verbose`/`:clean`)
  - added `%plist-has-key`
- `lisp/src/evaluator.lisp`
  - added clean-result behavior for noisy registration ops
  - `режим` now supports `:вывод clean|verbose` (and combined with language switch)
- `lisp/src/repl.lisp`
  - banner shows output mode
  - added help lines for Russian query heads
  - added `:silent` result handling
  - normalized library card heads to Russian labels (`[категория]`, `[фигура]`, ...)

### Verification executed
- Lisp runtime launched directly in terminal: `bash lisp/scripts/run_truerul.sh`
- Command batches verified for:
  - RU forms and query heads
  - history/back/repeat/buffer/block/save flows
  - structural views and scheme views
  - clean/verbose output switch
- Web health and xterm CSS route verified:
  - `GET /health` -> ok, runtime=lisp
  - `/vendor/xterm/css/xterm.css` -> 200 OK

## Stage 2 — implemented

### Real adjacent contour beside nolcli
- Added script: `scripts/tmux/truerul_nol_side_panel.sh`

Behavior:
- attaches to existing tmux session (default `nevis`)
- creates window `TRUERUL-NOL`
- left pane starts live nolcli (`/srv/WORLD/projects/nevis_console_v0/bin/nol`)
- right pane starts Truerul Lisp heart (`bash lisp/scripts/run_truerul.sh`)

### Verification executed
- Script run successfully in live `nevis` session
- Pane capture shows:
  - left: `nol >`
  - right: `TRUERUL ... >`

## Stage 3 — implemented (prep contour)

### Local workbench-prep bootstrap
- Added script: `scripts/tmux/truerul_local_workbench.sh`

Behavior:
- creates local tmux session (default `truerul-local`) with 4 panes:
  - main console heart
  - form buffer shell
  - command/snippet palette shell
  - artifacts/view watcher

### Repo/run discipline documentation
- Added runbook: `docs/runbooks/RUNBOOK__TRUERUL__CONSOLE_TO_NOLCLI_TO_LOCAL_WORKBENCH__v1.md`
  - VPS -> GitHub -> laptop sync steps
  - local terminal/web run commands
  - side-panel and workbench launcher commands

### Hygiene
- `.gitignore` extended with runtime leftovers:
  - `lisp/artifacts/`
  - `apps/web/server.pid`
  - `apps/web/server-*.pid`
  - `apps/web/server*.log`

## Operational commands

### 1) Rebuild side-panel beside nolcli
```bash
cd /srv/truerul
scripts/tmux/truerul_nol_side_panel.sh nevis
```

### 2) Start local workbench-prep tmux contour
```bash
cd /srv/truerul
scripts/tmux/truerul_local_workbench.sh truerul-local
```

### 3) Restart web terminal
```bash
cd /srv/truerul
pkill -f 'node apps/web/server.js' || true
tmux has-session -t truerul-web 2>/dev/null && tmux kill-session -t truerul-web || true
tmux new-session -d -s truerul-web 'cd /srv/truerul && TRUERUL_RUNTIME=lisp TRUERUL_WEB_PORT=4173 node apps/web/server.js'
```
