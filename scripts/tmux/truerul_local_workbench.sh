#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SESSION_NAME="${1:-truerul-local}"
WINDOW_NAME="${TRUERUL_WORKBENCH_WINDOW:-workbench}"

if ! command -v tmux >/dev/null 2>&1; then
  echo "[error] tmux not found"
  exit 1
fi

if [[ ! -f "$ROOT_DIR/lisp/scripts/run_truerul.sh" ]]; then
  echo "[error] run script missing: $ROOT_DIR/lisp/scripts/run_truerul.sh"
  exit 1
fi

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  tmux kill-session -t "$SESSION_NAME"
fi

tmux new-session -d -s "$SESSION_NAME" -n "$WINDOW_NAME" -c "$ROOT_DIR"
MAIN_PANE="$(tmux list-panes -t "$SESSION_NAME:$WINDOW_NAME" -F '#{pane_id}' | head -n1)"

# Pane 0 (left): live Truerul console heart.
tmux send-keys -t "$MAIN_PANE" "cd '$ROOT_DIR' && bash lisp/scripts/run_truerul.sh" C-m

# Pane 1 (right top): form buffer / scratch commands.
BUFFER_PANE="$(tmux split-window -h -P -F '#{pane_id}' -t "$MAIN_PANE" -c "$ROOT_DIR")"
tmux send-keys -t "$BUFFER_PANE" "printf '[buffer] form scratch pane\n[hint] put reusable forms into lisp/artifacts/notes/\n[hint] run: ls -1 lisp/artifacts/notes\n\n'; bash" C-m

# Pane 2 (right middle): command palette / library navigation.
PALETTE_PANE="$(tmux split-window -v -P -F '#{pane_id}' -t "$BUFFER_PANE" -c "$ROOT_DIR")"
tmux send-keys -t "$PALETTE_PANE" "printf '[palette] quick commands\n(помощь)\n(вид категории)\n(вид напряжения)\n(схема субъект)\n(буфер)\n\n'; bash" C-m

# Pane 3 (right bottom): artifacts/view watcher.
VIEWS_PANE="$(tmux split-window -v -P -F '#{pane_id}' -t "$PALETTE_PANE" -c "$ROOT_DIR")"
tmux send-keys -t "$VIEWS_PANE" "cd '$ROOT_DIR' && while true; do clear; echo '[views/artifacts] latest files'; find lisp/artifacts -type f -printf '%TY-%Tm-%Td %TH:%TM:%TS %p\n' 2>/dev/null | sort -r | head -n 20; sleep 2; done" C-m

tmux select-layout -t "$SESSION_NAME:$WINDOW_NAME" main-vertical

# Keep main console focused.
tmux select-pane -t "$MAIN_PANE"

echo "[ok] local workbench-prep session ready: $SESSION_NAME"
echo "[hint] attach: tmux attach -t $SESSION_NAME"
