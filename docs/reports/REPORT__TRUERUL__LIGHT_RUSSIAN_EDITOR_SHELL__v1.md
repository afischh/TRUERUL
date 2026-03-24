# REPORT — Truerul Light Russian Editor Shell over Console v1

Date: 2026-03-24
Repo: `/srv/truerul`

## Goal status

Implemented working web shell v0 over the living console heart.

Delivered:
1. Central real terminal pane (xterm + PTY websocket)
2. Russian menu/action layer (`Консоль`, `Буфер`, `Библиотека`, `Виды`, `Схемы`, `История`, `Помощь`)
3. Form buffer pane with send line/selection/all
4. Library pane with practical RU-first command buttons
5. Views/schemes pane with artifact inspection/reinsertion
6. Mandatory `Назад` action (pane-back, fallback to `(назад)`)
7. Saved artifacts list/open/preview/insert/run-forms
8. VPS run path and local laptop downstream run path

## Exact changed files

- `apps/web/public/index.html`
- `apps/web/public/main.css`
- `apps/web/public/client.js`
- `apps/web/server.js`
- `docs/runbooks/RUNBOOK__TRUERUL__LIGHT_RUSSIAN_EDITOR_SHELL__v1.md`

## Runtime/API additions

Added read-only artifact API in web server:
- `GET /api/artifacts?bucket=notes|views|schemes`
- `GET /api/artifacts/:bucket/:file`

Used for shell pane `Виды` to inspect and reinsert saved files.

## Verified facts

- `node --check` passed for `server.js` and `client.js`
- `GET /health` returns `ok` with runtime=lisp
- `GET /api/artifacts?bucket=notes` returns real saved files
- websocket path `/ws` still yields banner, prompt and command execution

## Limits of v0 (explicit)

- Buffer execution is line-oriented (multi-line forms are split by lines)
- Artifact “run” executes lines that look like full forms `( ... )`
- No full visual text editor yet (intentionally light shell)
- No autocomplete/LSP/hints engine yet (palette + snippets only)

## Console heart preservation

- Direct terminal remains fully supported: `bash lisp/scripts/run_truerul.sh`
- tmux contours remain valid
- Shell is wrapper, not replacement
