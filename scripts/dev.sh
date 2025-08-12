#!/usr/bin/env bash
set -euo pipefail

# Load .env if present
if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

run_node() {
  if command -v node >/dev/null 2>&1 && [ -f src/index.js ]; then
    echo "[dev] Running Node app: src/index.js"
    exec node src/index.js
  fi
  return 1
}

run_python() {
  if command -v python >/dev/null 2>&1 && [ -f src/main.py ]; then
    echo "[dev] Running Python app: src/main.py"
    exec python src/main.py
  elif command -v python3 >/dev/null 2>&1 && [ -f src/main.py ]; then
    echo "[dev] Running Python3 app: src/main.py"
    exec python3 src/main.py
  fi
  return 1
}

if run_node; then exit 0; fi
if run_python; then exit 0; fi

echo "[dev] No runnable entrypoint found."
echo "- Create src/index.js (Node) or src/main.py (Python)"
exit 1
