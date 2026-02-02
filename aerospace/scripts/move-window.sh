#!/usr/bin/env bash
# move-window.sh — move the frontmost window
# Usage:
#   move-window.sh --to X Y        (absolute coords)
#   move-window.sh --delta DX DY   (relative move, e.g., +100 -50)
#   move-window.sh --dir left 50   (directional move, default 50)
#   move-window.sh --edge right 20 (snap to edge with padding)
#   move-window.sh --center       (center the window on current screen)

set -euo pipefail
LOG=/tmp/move-window.log
ASLOG=/tmp/move-window.applescript.log
echo "run: $(date) args: $*" >> "$LOG"

usage() {
  cat <<EOF
Usage:
  $0 --to X Y
  $0 --delta DX DY      (e.g. +100 -50)
  $0 --dir left|right|up|down [AMOUNT]
  $0 --edge top|bottom|left|right [PADDING]
  $0 --center

Examples:
  $0 --delta +100 0
  $0 --dir left 50
  $0 --edge right 20
EOF
}

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

action=""
arg1=""
arg2=""
amount=""
padding="0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --to)
      action=to; arg1="$2"; arg2="$3"; shift 3;;
    --delta)
      action=delta; arg1="$2"; arg2="$3"; shift 3;;
    --dir)
      action=dir; arg1="$2"; amount="${3:-50}"; shift $(( ${3:+2} )) ;;
    --edge)
      action=edge; arg1="$2"; padding="${3:-0}"; shift $(( ${3:+2} )) ;;
    --center)
      action=center; shift;;
    --help|-h)
      usage; exit 0;;
    *)
      echo "Unknown arg: $1" >> "$LOG"; usage; exit 2;;
  esac
done

if [ -z "$action" ]; then
  echo "No action specified" >> "$LOG"; usage; exit 2
fi

# Build AppleScript depending on action
case "$action" in
  to)
    X=${arg1}; Y=${arg2}
    APPLESCRIPT=$(cat <<AS
try
  tell application "System Events"
    set frontApp to first application process whose frontmost is true
    tell frontApp
      if (count of windows) = 0 then return
      set position of window 1 to {${X}, ${Y}}
    end tell
  end tell
end try
AS
)
    ;;
  delta)
    DX=${arg1}; DY=${arg2}
    APPLESCRIPT=$(cat <<AS
try
  tell application "System Events"
    set frontApp to first application process whose frontmost is true
    tell frontApp
      if (count of windows) = 0 then return
      set {wx, wy} to position of window 1
      set newx to wx + (${DX})
      set newy to wy + (${DY})
      set position of window 1 to {newx, newy}
    end tell
  end tell
  -- clamp to desktop bounds
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
    end tell
  end tell
end try
AS
)
    ;;
  dir)
    D=${amount}
    case "$arg1" in
      left) DX="-${D}"; DY=0;;
      right) DX="+${D}"; DY=0;;
      up) DX=0; DY="-${D}";;
      down) DX=0; DY="+${D}";;
      *) echo "Unknown direction: $arg1" >> "$LOG"; exit 2;;
    esac
    APPLESCRIPT=$(cat <<AS
try
  tell application "System Events"
    set frontApp to first application process whose frontmost is true
    tell frontApp
      if (count of windows) = 0 then return
      set {wx, wy} to position of window 1
      set newx to wx + (${DX})
      set newy to wy + (${DY})
      set position of window 1 to {newx, newy}
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
    end tell
  end tell
end try
AS
)
    ;;
  edge)
    P=${padding}
    case "$arg1" in
      left)
        APPLESCRIPT=$(cat <<AS
try
  tell application "Finder"
    set desktopBounds to bounds of window of desktop
  end tell
  set {sx, sy, sw, sh} to desktopBounds
  tell application "System Events"
    tell (first application process whose frontmost is true)
      if (count of windows) = 0 then return
      set {ww, wh} to size of window 1
      set newx to sx + ${P}
      set {_, wy} to position of window 1
      set position of window 1 to {newx, wy}
    end tell
  end tell
end try
AS
)
        ;;
      right)
        APPLESCRIPT=$(cat <<AS
try
  tell application "Finder"
    set desktopBounds to bounds of window of desktop
  end tell
  set {sx, sy, sw, sh} to desktopBounds
  tell application "System Events"
    tell (first application process whose frontmost is true)
      if (count of windows) = 0 then return
      set {ww, wh} to size of window 1
      set newx to sw - ww - ${P}
      set {_, wy} to position of window 1
      set position of window 1 to {newx, wy}
    end tell
  end tell
end try
AS
)
        ;;
      top)
        APPLESCRIPT=$(cat <<AS
try
  tell application "Finder"
    set desktopBounds to bounds of window of desktop
  end tell
  set {sx, sy, sw, sh} to desktopBounds
  tell application "System Events"
    tell (first application process whose frontmost is true)
      if (count of windows) = 0 then return
      set {ww, wh} to size of window 1
      set newy to sy + ${P}
      set {wx, _} to position of window 1
      set position of window 1 to {wx, newy}
    end tell
  end tell
end try
AS
)
        ;;
      bottom)
        APPLESCRIPT=$(cat <<AS
try
  tell application "Finder"
    set desktopBounds to bounds of window of desktop
  end tell
  set {sx, sy, sw, sh} to desktopBounds
  tell application "System Events"
    tell (first application process whose frontmost is true)
      if (count of windows) = 0 then return
      set {ww, wh} to size of window 1
      set newy to sh - wh - ${P}
      set {wx, _} to position of window 1
      set position of window 1 to {wx, newy}
    end tell
  end tell
end try
AS
)
        ;;
      *) echo "Unknown edge: $arg1" >> "$LOG"; exit 2;;
    esac
    ;;
  center)
    APPLESCRIPT=$(cat <<AS
try
  tell application "Finder"
    set desktopBounds to bounds of window of desktop
  end tell
  set {sx, sy, sw, sh} to desktopBounds
  tell application "System Events"
    tell (first application process whose frontmost is true)
      if (count of windows) = 0 then return
      set {ww, wh} to size of window 1
      set newx to sx + (((sw - sx) - ww) / 2)
      set newy to sy + (((sh - sy) - wh) / 2)
      set position of window 1 to {newx, newy}
    end tell
  end tell
end try
AS
)
    ;;
esac

# Execute applescript
osascript -e "$APPLESCRIPT" >> "$LOG" 2>>"$ASLOG" || echo "osascript returned non-zero" >> "$LOG"

echo "done: $(date)" >> "$LOG"
exit 0
