#!/usr/bin/env bash
set -euo pipefail

# validate_repo_access.sh
#
# Usage:
#   scripts/validate_repo_access.sh <git_remote_url> [ref]
#
# Description:
#   Validates read access to a Git remote without cloning the repository
#   by using `git ls-remote`. If an optional ref (branch/tag) is provided,
#   validation ensures that ref exists remotely.
#
# Notes:
#   - This script intentionally avoids committing any Git metadata or
#     bare repositories into this source tree.
#   - Authentication can be provided via the URL itself or environment
#     (e.g., SSH agent, credential helpers).

if [[ ${1:-} == "-h" || ${1:-} == "--help" || $# -lt 1 ]]; then
  echo "Usage: $0 <git_remote_url> [ref]" >&2
  exit 2
fi

REMOTE_URL="$1"
REF="${2:-}"

if [[ -z "$REF" ]]; then
  if git ls-remote --exit-code "$REMOTE_URL" >/dev/null 2>&1; then
    echo "OK: remote is accessible"
    exit 0
  else
    echo "ERROR: remote is not accessible or credentials are missing" >&2
    exit 1
  fi
else
  if git ls-remote --exit-code "$REMOTE_URL" "$REF" >/dev/null 2>&1; then
    echo "OK: remote is accessible and ref '$REF' exists"
    exit 0
  else
    echo "ERROR: remote is not accessible or ref '$REF' does not exist" >&2
    exit 1
  fi
fi

