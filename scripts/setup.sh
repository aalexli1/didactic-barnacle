#!/usr/bin/env bash
set -euo pipefail

echo "[setup] Making scripts executable..."
chmod +x scripts/*.sh 2>/dev/null || true

echo "[setup] Done."
