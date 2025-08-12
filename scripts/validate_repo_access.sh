#!/usr/bin/env bash
set -euo pipefail

# Run from anywhere: resolve repo root (parent of scripts/)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VALIDATOR_PY="${REPO_ROOT}/tools/validate_repo_access.py"

REMOTE_URL="${1:-}"

if [[ -z "${REMOTE_URL}" ]]; then
  echo "Usage: $0 <remote-url> [--no-push] [--keep]" >&2
  exit 2
fi

if [[ ! -f "${VALIDATOR_PY}" ]]; then
  echo "Error: missing validator script at ${VALIDATOR_PY}." >&2
  echo "Ensure tools/validate_repo_access.py exists before running this script." >&2
  exit 1
fi

shift || true

exec python "${VALIDATOR_PY}" --remote "${REMOTE_URL}" "$@"
