#!/usr/bin/env bash
set -euo pipefail

SESSION_NAME="${1:-nevis}"
WINDOW_NAME="${TRUERUL_NOL_WINDOW:-TRUERUL-NOL}"
NOL_ROOT="${NOL_ROOT:-/srv/WORLD/projects/nevis_console_v0}"
TRUERUL_ROOT="${TRUERUL_ROOT:-/srv/truerul}"
NOL_CMD="${NOL_CMD:-./bin/nol}"
TRUERUL_CMD="${TRUERUL_CMD:-bash lisp/scripts/run_truerul.sh}"

if ! command -v tmux >/dev/null 2>&1; then
  echo "[error] tmux not found"
  exit 1
fi

if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "[error] tmux session not found: $SESSION_NAME"
  echo "[hint] create/attach session first, e.g. tmux new -s $SESSION_NAME"
  exit 1
fi

if [[ ! -x "$NOL_ROOT/bin/nol" ]]; then
  echo "[error] live nol entrypoint missing: $NOL_ROOT/bin/nol"
  exit 1
fi

if [[ ! -f "$TRUERUL_ROOT/lisp/scripts/run_truerul.sh" ]]; then
  echo "[error] truerul lisp runtime script not found: $TRUERUL_ROOT/lisp/scripts/run_truerul.sh"
  exit 1
fi

if tmux list-windows -t "$SESSION_NAME" -F '#{window_name}' | grep -Fxq "$WINDOW_NAME"; then
  tmux kill-window -t "$SESSION_NAME:$WINDOW_NAME"
fi

tmux new-window -t "$SESSION_NAME" -n "$WINDOW_NAME" -c "$NOL_ROOT"
LEFT_PANE="$(tmux list-panes -t "$SESSION_NAME:$WINDOW_NAME" -F '#{pane_id}' | head -n1)"
tmux send-keys -t "$LEFT_PANE" "cd '$NOL_ROOT' && $NOL_CMD" C-m

RIGHT_PANE="$(tmux split-window -h -P -F '#{pane_id}' -t "$LEFT_PANE" -c "$TRUERUL_ROOT")"
tmux send-keys -t "$RIGHT_PANE" "cd '$TRUERUL_ROOT' && $TRUERUL_CMD" C-m

tmux select-layout -t "$SESSION_NAME:$WINDOW_NAME" even-horizontal
# Keep nolcli as primary focus pane; truerul as adjacent instrument.
tmux select-pane -t "$LEFT_PANE"

echo "[ok] window ready: $SESSION_NAME:$WINDOW_NAME"
echo "[ok] left pane: nolcli ($NOL_ROOT)"
echo "[ok] right pane: truerul lisp ($TRUERUL_ROOT)"
echo "[hint] attach: tmux attach -t $SESSION_NAME"
