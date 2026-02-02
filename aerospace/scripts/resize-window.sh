#!/usr/bin/env bash
# resize-window.sh — resize the frontmost window
# Usage:
#   resize-window.sh --set WxH [--center]
#   resize-window.sh --delta DW DH [--center]
# Examples:
#   resize-window.sh --set 1200x800
#   resize-window.sh --delta +100 -50 --center

set -euo pipefail
LOG=/tmp/resize-window.log
ASLOG=/tmp/resize-window.applescript.log
echo "run: $(date) args: $*" >> "$LOG"

usage() {
  cat <<EOF
Usage:
  $0 --set WIDTHxHEIGHT [--center]
  $0 --delta WIDTH_DELTA HEIGHT_DELTA [--center]

Examples:
  $0 --set 1200x800
  $0 --delta +100 -50 --center
EOF
}

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

set_args=""
delta_w=""
delta_h=""
center=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --set)
      set_args="$2"
      shift 2
      ;;
    --delta)
      delta_w="$2"; delta_h="$3"; shift 3
      ;;
    --center)
      center=1; shift
      ;;
    --help|-h)
      usage; exit 0
      ;;
    *)
      echo "Unknown arg: $1" >> "$LOG"
      usage; exit 2
      ;;
  esac
done

if [ -z "$set_args" ] && [ -z "$delta_w" ]; then
  echo "No resize arguments provided" >> "$LOG"
  usage
  exit 2
fi

# Build AppleScript with embedded values
if [ -n "$set_args" ]; then
  IFS='x' read -r NEW_W NEW_H <<< "$set_args"
  APPLESCRIPT=$(cat <<AS
try
  tell application "System Events"
    set frontApp to first application process whose frontmost is true
    tell frontApp
      if (count of windows) = 0 then return
      set win to window 1
      set {wx, wy} to position of win
      set {ww, wh} to size of win
      set newW to ${NEW_W}
      set newH to ${NEW_H}
      if newW < 100 then set newW to 100
      if newH < 44 then set newH to 44
      set size of window 1 to {newW, newH}
    end tell
  end tell
  tell application "Finder"
    set desktopBounds to bounds of window of desktop
  end tell
  set {sx, sy, sw, sh} to desktopBounds
  -- Ensure window is within bounds
  tell application "System Events"
    tell (first application process whose frontmost is true)
      set {wx, wy} to position of window 1
      set {ww, wh} to size of window 1
      if wx < sx then set wx to sx
      if wy < sy then set wy to sy
      if (wx + ww) > sw then set wx to sw - ww
      if (wy + wh) > sh then set wy to sh - wh
      set position of window 1 to {wx, wy}
      
AS
)
  if [ "$center" -eq 1 ]; then
    APPLESCRIPT+=$'\n      -- center after resize\n      set {sx, sy, sw, sh} to desktopBounds\n      set newx to sx + (((sw - sx) - newW) / 2)\n      set newy to sy + (((sh - sy) - newH) / 2)\n      set position of window 1 to {newx, newy}\n'
  fi
  APPLESCRIPT+=$'\n    end tell\nend try'
else
  # delta case
  # remove plus signs for integer arithmetic in AppleScript by adding them to strings is okay
  DW=${delta_w}
  DH=${delta_h}
  APPLESCRIPT=$(cat <<AS
try
  tell application "System Events"
    set frontApp to first application process whose frontmost is true
    tell frontApp
      if (count of windows) = 0 then return
      set win to window 1
      set {wx, wy} to position of win
      set {ww, wh} to size of win
      set newW to ww + (${DW})
      set newH to wh + (${DH})
      if newW < 100 then set newW to 100
      if newH < 44 then set newH to 44
      set size of window 1 to {newW, newH}
    end tell
  end tell
  tell application "Finder"
    set desktopBounds to bounds of window of desktop
  end tell
  set {sx, sy, sw, sh} to desktopBounds
  tell application "System Events"
    tell (first application process whose frontmost is true)
      set {wx, wy} to position of window 1
      set {ww, wh} to size of window 1
      if wx < sx then set wx to sx
      if wy < sy then set wy to sy
      if (wx + ww) > sw then set wx to sw - ww
      if (wy + wh) > sh then set wy to sh - wh
      set position of window 1 to {wx, wy}
AS
)
  if [ "$center" -eq 1 ]; then
    APPLESCRIPT+=$'\n      -- center after resize\n      set {sx, sy, sw, sh} to desktopBounds\n      set newx to sx + (((sw - sx) - newW) / 2)\n      set newy to sy + (((sh - sy) - newH) / 2)\n      set position of window 1 to {newx, newy}\n'
  fi
  APPLESCRIPT+=$'\n    end tell\nend try'
fi

# Run applescript
osascript -e "$APPLESCRIPT" >> "$LOG" 2>>"$ASLOG" || echo "osascript returned non-zero" >> "$LOG"

echo "done: $(date)" >> "$LOG"

exit 0
