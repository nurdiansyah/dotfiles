#!/usr/bin/env bash
# kanatactl.sh — manage the Kanata system daemon (and a foreground debug mode)
# Location: kanata/kanatactl.sh
# Purpose: single convenient entrypoint to start/stop/restart/status/reload the
#          system LaunchDaemon and to run Kanata in foreground for debugging.

set -euo pipefail
PROG=$(basename "$0")
DAEMON_LABEL="org.nurdiansyah.kanata"
PLIST_PATH="/Library/LaunchDaemons/${DAEMON_LABEL}.plist"
INSTALLED_CFG="/Library/Application Support/kanata/kanata.kbd"
REPO_CFG="$HOME/dotfiles/kanata/kanata.kbd"
KANATA_BIN="$(command -v kanata || true)"
FORCE=false
QUIET=false
INSTALL_OPTS=""

usage() {
  cat <<-USAGE
Usage: $PROG <command> [--yes] [--src PATH]

Commands:
  status         Show daemon status, pid, installed config and comparisons
  start          Bootstrap/start the system LaunchDaemon (requires sudo)
  stop           Unload/stop the LaunchDaemon (requires sudo)
  restart        Restart the LaunchDaemon (requires sudo)
  reload         Instruct launchd to reload the running daemon (kickstart -k)
  install-config Copy repo config -> ${INSTALLED_CFG} (uses kanata/install-kanata-config.sh)
  clean          Remove all saved config backups (/var/tmp/kanata-config-backups) (requires sudo)
  foreground     Run kanata in foreground for debugging (blocks)
  help           Show this help

Options:
  --yes          Skip confirmation prompts for destructive actions
  --src PATH     Use PATH as source when running install-config
  --install-opts Pass extra options (quoted) to install-kanata-config.sh (e.g. "--force --dry-run")
  --quiet        Minimize output

Examples:
  sudo $PROG start
  sudo $PROG install-config --src ~/dotfiles/kanata/kanata.kbd
  $PROG foreground   # run in foreground (for testing)  

Notes:
- start/stop/restart/install-config require sudo because they operate on system locations.
- Use 'foreground' to debug key events (stop the daemon first if running).
USAGE
}

confirm() {
  if [ "$FORCE" = true ] || [ "$QUIET" = true ]; then
    return 0
  fi
  read -r -p "$1 [y/N]: " ans
  case "$ans" in
    [Yy]|[Yy][Ee][Ss]) return 0 ;;
    *) return 1 ;;
  esac
}

die() { echo "ERROR: $*" >&2; exit 2; }
info() { [ "$QUIET" = true ] || echo "$*"; }

cmd_status() {
  info "== Kanata status =="
  if sudo launchctl print system/${DAEMON_LABEL} >/dev/null 2>&1; then
    sudo launchctl print system/${DAEMON_LABEL} | grep -E 'pid =|state =|stdout path' || true
  else
    echo "daemon: not-loaded"
    sudo launchctl list | grep -E 'kanata|org.nurdiansyah' || true
  fi

  echo
  echo "binary: ${KANATA_BIN:-not-found}"
  echo "repo cfg: ${REPO_CFG}"
  echo "installed cfg: ${INSTALLED_CFG}"
  if [ -f "$REPO_CFG" ] && [ -f "$INSTALLED_CFG" ]; then
    if cmp -s "$REPO_CFG" "$INSTALLED_CFG"; then
      echo "config: repo == installed"
    else
      echo "config: repo != installed"
    fi
  else
    [ -f "$REPO_CFG" ] || echo "config: repo missing ($REPO_CFG)"
    [ -f "$INSTALLED_CFG" ] || echo "config: installed missing ($INSTALLED_CFG)"
  fi
}

cmd_start() {
  [ -f "$PLIST_PATH" ] || die "$PLIST_PATH not found; install the LaunchDaemon first"
  info "Bootstrapping $DAEMON_LABEL... (may require sudo)"
  sudo launchctl bootstrap system "$PLIST_PATH" || sudo launchctl kickstart -k system/${DAEMON_LABEL}
  sleep 0.4
  cmd_status
}

cmd_stop() {
  info "Stopping $DAEMON_LABEL..."
  sudo launchctl bootout system "$PLIST_PATH" || sudo launchctl unload "$PLIST_PATH" || true
  sleep 0.2
  cmd_status
}

cmd_restart() {
  info "Restarting $DAEMON_LABEL..."
  if sudo launchctl print system/${DAEMON_LABEL} >/dev/null 2>&1; then
    sudo launchctl kickstart -k system/${DAEMON_LABEL}
  else
    cmd_start
  fi
  sleep 0.4
  cmd_status
}

cmd_reload() {
  info "Reloading (kickstart -k) ${DAEMON_LABEL}"
  sudo launchctl kickstart -k system/${DAEMON_LABEL}
  sleep 0.2
  cmd_status
}

cmd_clean() {
  BACKUP_DIR="/var/tmp/kanata-config-backups"
  if [ ! -d "$BACKUP_DIR" ]; then
    info "No backups found ($BACKUP_DIR)"
    return 0
  fi
  info "Backups in $BACKUP_DIR:"
  ls -1 "$BACKUP_DIR" || true
  confirm "Remove all backups in $BACKUP_DIR?" || return 1
  sudo rm -f "$BACKUP_DIR"/* || true
  info "Removed backups from $BACKUP_DIR"
}

cmd_install_config() {
  SRC="$1"
  if [ -z "$SRC" ] || [ ! -f "$SRC" ]; then
    die "source config missing: $SRC"
  fi
  confirm "Install $SRC -> $INSTALLED_CFG and restart daemon?" || return 1
  sudo bash "$(dirname "$0")/install-kanata-config.sh" --src "$SRC" ${INSTALL_OPTS:-}
}

cmd_foreground() {
  CFG="${1:-$REPO_CFG}"
  if [ ! -f "$CFG" ]; then
    die "config not found: $CFG"
  fi
  info "Run kanata in foreground for debug (config: $CFG) — press lctl+spc+esc to exit"
  # Stop system daemon if running to avoid conflicts
  if sudo launchctl print system/${DAEMON_LABEL} >/dev/null 2>&1; then
    info "Temporarily stopping system daemon. It will NOT be restarted automatically; after you exit foreground mode, run: sudo $0 start"
    sudo launchctl bootout system "$PLIST_PATH" || true
  fi
  [ -z "$KANATA_BIN" ] && die "kanata binary not found in PATH"
  "$KANATA_BIN" -c "$CFG"
}

# --- parse args ---
if [ "$#" -lt 1 ]; then
  usage
  exit 0
fi

CMD="$1"; shift || true
while [ "$#" -gt 0 ]; do
  case "$1" in
    --yes) FORCE=true ;;
    --install-opts)
      shift
      [ -z "${1:-}" ] && die "--install-opts requires an argument"
      INSTALL_OPTS="$1"
      ;;
    --src)
      shift
      [ -z "${1:-}" ] && die "--src requires an argument"
      SRC_ARG="$1"
      ;;
    --quiet) QUIET=true ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown arg: $1" ;;
  esac
  shift
done

case "$CMD" in
  status) cmd_status ;;
  start) cmd_start ;;
  stop) cmd_stop ;;
  restart) cmd_restart ;;
  reload) cmd_reload ;;
  clean) cmd_clean ;;
  install-config) cmd_install_config "${SRC_ARG:-$REPO_CFG}" ;;
  foreground) cmd_foreground "${SRC_ARG:-$REPO_CFG}" ;;
  help) usage ;;
  *) die "unknown command: $CMD" ;;
esac
