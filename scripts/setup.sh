#!/usr/bin/env bash
set -euo pipefail

echo "[setup] Making scripts executable..."
if [ -d scripts ]; then
  # Only chmod if there are .sh files; avoid masking real errors
  sh_files=$(ls scripts/*.sh 2>/dev/null || true)
  if [ -n "$sh_files" ]; then
    chmod +x scripts/*.sh
  else
    echo "[setup] No shell scripts found in ./scripts" >&2
  fi
else
  echo "[setup] Directory ./scripts not found" >&2
fi

echo "[setup] Done."
