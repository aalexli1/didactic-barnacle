#!/usr/bin/env bash
set -euo pipefail

# Ensure we are running with bash even if invoked via `sh`.
if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

# Safely load .env without executing it (no sourcing).
# Supports simple KEY=VALUE pairs with optional single/double quotes.
load_env_file() {
  local env_file=${1:-.env}
  [ -f "$env_file" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    # Trim leading/trailing whitespace
    line=$(printf '%s' "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    # Skip comments and blank lines
    [[ -z "$line" || ${line:0:1} == "#" ]] && continue
    # Only accept KEY=VALUE pattern with safe var name
    if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
      local key=${BASH_REMATCH[1]}
      local val=${BASH_REMATCH[2]}
      # Remove surrounding quotes if present
      if [[ "$val" =~ ^\".*\"$ ]]; then
        val=${val:1:${#val}-2}
      elif [[ "$val" =~ ^\'.*\'$ ]]; then
        val=${val:1:${#val}-2}
      fi
      # Export without eval; values are taken literally
      printf -v "$key" '%s' "$val"
      export "$key"
    fi
  done < "$env_file"
}

# Load .env if present (safely)
load_env_file .env

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
