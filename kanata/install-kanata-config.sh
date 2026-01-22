#!/usr/bin/env bash
# Install ~/dotfiles/kanata/kanata.kbd → /Library/Application Support/kanata/kanata.kbd
# - safe backup
# - idempotent (no-op if identical)
# - sets ownership/mode expected by LaunchDaemon
# - restarts the Kanata LaunchDaemon

set -euo pipefail
SRC_DEFAULT="$HOME/dotfiles/kanata/kanata.kbd"
DST="/Library/Application Support/kanata/kanata.kbd"
BACKUP_DIR="/var/tmp/kanata-config-backups"
DRY_RUN=false
FORCE=false

usage() {
  cat <<-USAGE
Usage: sudo $(basename "$0") [--src PATH] [--dry-run] [--force]

Installs the repository Kanata config to the system location and reloads the
system LaunchDaemon. Safe: existing file is backed up with a timestamp.

Options:
  --src PATH    Path to source kanata.kbd (default: $SRC_DEFAULT)
  --dry-run     Show actions that would be taken, do not modify system
  --force       Overwrite even if files appear identical (still creates backup)
  -h, --help    Show this help

Example:
  sudo $(basename "$0") --src ~/dotfiles/kanata/kanata.kbd
  sudo $(basename "$0") --dry-run

Security: this script requires sudo for install and restart steps.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --src) shift; SRC="$1" ;;
    --dry-run) DRY_RUN=true ;;
    --force) FORCE=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
  shift
done

SRC=${SRC:-$SRC_DEFAULT}

if [ ! -f "$SRC" ]; then
  echo "ERROR: source config not found: $SRC" >&2
  exit 2
fi

echo "Install Kanata config"
echo "  src: $SRC"
echo "  dst: $DST"
[ "$DRY_RUN" = true ] && echo "  mode: dry-run"

# Compare
if sudo test -f "$DST" >/dev/null 2>&1; then
  if sudo cmp -s "$SRC" "$DST" >/dev/null 2>&1; then
    if [ "$FORCE" = false ]; then
      echo "No changes detected between $SRC and $DST. Nothing to do.";
      exit 0
    else
      echo "Files are identical but --force given; will reinstall and restart.";
    fi
  else
    echo "Installed config differs — will replace (backup will be created)."
  fi
else
  echo "No installed config found — will install.";
fi

if [ "$DRY_RUN" = true ]; then
  echo "DRY RUN: would perform backup, copy, chown, chmod, and launchctl kickstart.";
  exit 0
fi

# Ensure backup dir
sudo mkdir -p "$BACKUP_DIR"
TS=$(date -u +%Y%m%dT%H%M%SZ)
if sudo test -f "$DST" >/dev/null 2>&1; then
  BAK="$BACKUP_DIR/kanata.kbd.bak.$TS"
  echo "Backing up existing installed config → $BAK"
  sudo cp -p "$DST" "$BAK"
fi

# Copy into place
echo "Copying $SRC → $DST"
sudo install -v -m 0644 -o root -g wheel "$SRC" "$DST"

# Verify
if sudo cmp -s "$SRC" "$DST"; then
  echo "Installed file matches source (ok)"
else
  echo "ERROR: after copy, installed file differs from source" >&2
  exit 3
fi

# Restart daemon
echo "Reloading Kanata LaunchDaemon"
sudo launchctl kickstart -k system/org.nurdiansyah.kanata

echo "Done — Kanata config installed and daemon kicked."
exit 0
