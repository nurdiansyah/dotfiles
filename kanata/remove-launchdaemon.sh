#!/usr/bin/env bash
# Uninstall Kanata LaunchDaemon and remove installed config

set -euo pipefail
PLIST_NAME="org.nurdiansyah.kanata.plist"
PLIST_DST="/Library/LaunchDaemons/${PLIST_NAME}"
KADATA_DIR="/Library/Application Support/kanata"

if [ "$EUID" -ne 0 ]; then
  echo "❌ This script must be run as root (sudo)."
  echo "  sudo $0"
  exit 1
fi

echo "🚮 Removing Kanata LaunchDaemons and Karabiner helpers"

PLISTS=(
  "/Library/LaunchDaemons/org.nurdiansyah.kanata.plist"
  "/Library/LaunchDaemons/org.pqrs.karabiner.vhiddaemon.plist"
  "/Library/LaunchDaemons/org.pqrs.karabiner.vhidmanager.plist"
)

for p in "${PLISTS[@]}"; do
  if [ -f "$p" ]; then
    echo "🔄 Unloading: $p"
    launchctl bootout system "$p" 2>/dev/null || launchctl unload -w "$p" 2>/dev/null || true
    echo "🗑️ Removing plist: $p"
    rm -f "$p"
  else
    echo "ℹ️ Plist not found: $p"
  fi
done

# Optionally remove config
if [ -d "$KADATA_DIR" ]; then
  echo "⚠️ Config directory exists: $KADATA_DIR"
  read -p "Remove config directory $KADATA_DIR? [y/N]: " yn
  case "$yn" in
    [Yy]* ) rm -rf "$KADATA_DIR"; echo "Removed $KADATA_DIR";;
    * ) echo "Left $KADATA_DIR";;
  esac
fi

echo "✅ Uninstall complete"
