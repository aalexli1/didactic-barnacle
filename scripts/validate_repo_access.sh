#!/usr/bin/env bash
set -euo pipefail

REMOTE_URL="${1:-}"

if [[ -z "${REMOTE_URL}" ]]; then
  echo "Usage: $0 <remote-url> [--no-push] [--keep]" >&2
  exit 2
fi

shift || true

exec python tools/validate_repo_access.py --remote "${REMOTE_URL}" "$@"

