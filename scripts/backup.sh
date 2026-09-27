#!/usr/bin/env bash
# Consistent world snapshot while the server is running.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
load_env
RCON="$ROOT/scripts/rcon.py"
REV="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo no-commit)"
OUT="$ROOT/backups/world-$(date +%Y-%m-%d-%H%M)-$REV.tar.zst"
mkdir -p "$ROOT/backups"

"$RCON" "save-off" "save-all flush"
trap '"$RCON" "save-on"' EXIT
tar -cf - -C "$ROOT/server" world | zstd -T0 -3 -q -o "$OUT"
echo "backup: $OUT"
