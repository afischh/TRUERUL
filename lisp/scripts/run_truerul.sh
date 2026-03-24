#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if command -v sbcl >/dev/null 2>&1; then
  exec sbcl \
    --noinform \
    --non-interactive \
    --eval '(setf *load-verbose* nil *load-print* nil *compile-verbose* nil *compile-print* nil)' \
    --load "$ROOT_DIR/truerul-runtime.asd" \
    --eval '(asdf:load-system :truerul-runtime)' \
    --eval '(truerul-runtime:run-truerul-repl)'
else
  echo "Truerul Lisp heart needs SBCL in PATH." >&2
  exit 1
fi
