#!/usr/bin/env bash
set -euo pipefail
#
# Create a symlink from $XDG_CONFIG_HOME/kanata -> $HOME/dotfiles/kanata
#
DEST_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/kanata"
SRC_DIR="$HOME/dotfiles/kanata"

echo "🔗 Linking Kanata config"
echo "Source: $SRC_DIR"
echo "Destination: $DEST_DIR"

if [ ! -d "$SRC_DIR" ]; then
  echo "❌ Source not found: $SRC_DIR"
  exit 1
fi

mkdir -p "$(dirname "$DEST_DIR")"

if [ -e "$DEST_DIR" ] && [ ! -L "$DEST_DIR" ]; then
  BACKUP="${DEST_DIR}.bak.$(date +%s)"
  echo "⚠️ Destination exists and is not a symlink. Moving to: $BACKUP"
  mv "$DEST_DIR" "$BACKUP"
fi

ln -sfn "$SRC_DIR" "$DEST_DIR"
echo "✅ Created symlink: $DEST_DIR -> $SRC_DIR"

# Basic validation
if [ -f "$DEST_DIR/kanata.kbd" ]; then
  if command -v kanata &>/dev/null && kanata -c "$DEST_DIR/kanata.kbd" --check &>/dev/null; then
    echo "✓ Config validated: $DEST_DIR/kanata.kbd"
  else
    echo "⚠️ Config validation failed or 'kanata' not installed. Run: kanata -c $DEST_DIR/kanata.kbd --check"
  fi
else
  echo "⚠️ No kanata.kbd at $DEST_DIR — check $SRC_DIR"
fi
