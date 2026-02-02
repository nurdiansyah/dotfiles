#!/usr/bin/env bash
set -euo pipefail
LOG=/tmp/center-window.log
echo "run: $(date)" >> "$LOG"
DIR="$(cd "$(dirname "$0")" && pwd)"
if ! command -v osascript >/dev/null 2>&1; then
  echo "osascript not found" >> "$LOG"
  exit 1
fi
osascript "$DIR/center-window.applescript" >> "$LOG" 2>&1 || echo "osascript failed: $?" >> "$LOG"
