#!/usr/bin/env bash
set -euo pipefail

ROLE="parse-assist"
INPUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --role)
      ROLE="${2:-parse-assist}"
      shift 2
      ;;
    --input)
      INPUT="${2:-}"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

MODEL="${TRUERUL_ASSIST_MODEL:-qwen2.5:1.5b-instruct}"

if [[ "${TRUERUL_ASSIST_USE_OLLAMA:-0}" == "1" ]] && command -v ollama >/dev/null 2>&1; then
  PROMPT=$'Ты lightweight assist-layer для Truerul.\n'\
$'Роль: '"$ROLE"$'\n'\
$'Ограничения: не делай финальных доказательств, не объявляй финальную истину, не строй автономную онтологию.\n'\
$'Дай 3-5 коротких технических подсказок для маршрутизации/.lib/нормализации.\n'\
$'Ввод оператора: '"$INPUT"

  ollama run "$MODEL" "$PROMPT" | sed '/^\s*$/d' | head -n 8
  exit 0
fi

echo "assist-fallback: heuristic-only route (set TRUERUL_ASSIST_USE_OLLAMA=1 to enable ollama)"
echo "role=$ROLE"
echo "hint: нормализовать ввод в формы запроса и применить фильтры domain/logic-mode/input-kind"
