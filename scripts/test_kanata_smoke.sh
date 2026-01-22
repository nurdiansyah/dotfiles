#!/usr/bin/env bash
# Quick smoke-test for Kanata (non-destructive)
# Usage:
#   ./scripts/test_kanata_smoke.sh        # quick user-level checks
#   ./scripts/test_kanata_smoke.sh --full # include driver/daemon checks (requires sudo)

set -euo pipefail
readonly PROG=$(basename "$0")
FULL=false
QUIET=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --full) FULL=true ;; 
    --quiet|-q) QUIET=true ;;
    -h|--help)
      cat <<-USAGE
Usage: $PROG [--full] [--quiet]

Quick, opinionated smoke-test for Kanata installation and runtime.

--full   Run driver/daemon checks that require sudo (recommended for CI on trusted hosts)
--quiet  Minimize output; exit codes still indicate status

Exit codes:
  0  all checks passed
  1  one or more checks failed

USAGE
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

# Helpers
ok() { [ "$QUIET" = true ] || echo "[OK]    $1"; }
warn() { [ "$QUIET" = true ] || echo "[WARN]  $1"; }
fail() { echo "[FAIL]  $1" >&2; FAILED=true; }

FAILED=false

echo "Kanata smoke-test — quick checks (use --full for driver checks)"

# 1) Binary + version
if command -v kanata >/dev/null 2>&1; then
  KPATH=$(command -v kanata)
  KVER=$(kanata --version 2>&1 || true)
  ok "kanata binary found: $KPATH — $KVER"
else
  fail "kanata not found in PATH"
fi

# 2) Config validity (prefer XDG, fallback to repo)
XDG_CFG="${XDG_CONFIG_HOME:-$HOME/.config}/kanata/kanata.kbd"
REPO_CFG="$HOME/dotfiles/kanata/kanata.kbd"
if [ -f "$XDG_CFG" ] && kanata -c "$XDG_CFG" --check >/dev/null 2>&1; then
  ok "config (XDG) valid: $XDG_CFG"
elif [ -f "$REPO_CFG" ] && kanata -c "$REPO_CFG" --check >/dev/null 2>&1; then
  ok "config (repo) valid: $REPO_CFG"
else
  warn "kanata config not found or failed --check; run: kanata -c ~/.config/kanata/kanata.kbd --check"
fi

# 3) Process (user-mode or system daemon)
if pgrep -fl kanata >/dev/null 2>&1; then
  ok "kanata process running"
else
  warn "kanata process not found — if you expect it as a daemon, check launchctl"
fi

# 4) Quick functional check (non-destructive)
# We can't synthesize a real keypress reliably here; advise manual verification
echo "Functional (manual):" 
echo "  - Tap CapsLock (should act as Escape by default)."
echo "  - Or run: kanata -c ~/.config/kanata/kanata.kbd (foreground) and observe output."

# FULL checks (driver / socket / launchd)
if [ "$FULL" = true ]; then
  echo "Driver/daemon checks (requires sudo)"

  # systemextensionsctl (DriverKit)
  if command -v systemextensionsctl >/dev/null 2>&1; then
    if systemextensionsctl list | grep -iq karabiner; then
      ok "Karabiner DriverKit appears installed (systemextensionsctl)"
    else
      fail "Karabiner DriverKit not listed by systemextensionsctl"
    fi
  else
    warn "systemextensionsctl not available on this macOS — skipping DriverKit listing"
  fi

  # launchd checks
  if sudo launchctl print system/org.pqrs.karabiner.vhiddaemon >/dev/null 2>&1; then
    ok "org.pqrs.karabiner.vhiddaemon loaded"
  else
    warn "org.pqrs.karabiner.vhiddaemon not loaded"
  fi

  if sudo launchctl print system/org.nurdiansyah.kanata >/dev/null 2>&1; then
    ok "org.nurdiansyah.kanata loaded"
  else
    warn "org.nurdiansyah.kanata not loaded"
  fi

  # installed config matches repo?
  INSTALLED_CFG="/Library/Application Support/kanata/kanata.kbd"
  if sudo test -f "$INSTALLED_CFG" >/dev/null 2>&1; then
    if sudo cmp -s "$REPO_CFG" "$INSTALLED_CFG"; then
      ok "installed config matches repo: $INSTALLED_CFG"
    else
      warn "installed config differs from repo: $INSTALLED_CFG"
      warn "To install repo config: sudo bash kanata/install-kanata-config.sh --src \"$REPO_CFG\""
    fi
  else
    warn "installed config missing: $INSTALLED_CFG (run install script to deploy)"
  fi

  # VHID tmp dir permissions
  if sudo test -d "/Library/Application Support/org.pqrs/tmp/rootonly" >/dev/null 2>&1; then
    # normalize and validate owner/group/mode (accepts "700" or "0700" from stat)
    owner=$(sudo stat -f '%Su' "/Library/Application Support/org.pqrs/tmp/rootonly" 2>/dev/null || true)
    group=$(sudo stat -f '%Sg' "/Library/Application Support/org.pqrs/tmp/rootonly" 2>/dev/null || true)
    mode=$(sudo stat -f '%OLp' "/Library/Application Support/org.pqrs/tmp/rootonly" 2>/dev/null || true)
    mode=${mode##0} # strip leading zero if present

    if [ "$owner" = "root" ] && [ "$group" = "wheel" ] && [ "$mode" = "700" ]; then
      ok "VHID tmp dir ownership and mode are secure: ${mode} ${owner}:${group}"
    else
      fail "VHID tmp dir ownership/mode unexpected: ${mode} ${owner}:${group} — run: sudo chown root:wheel \"/Library/Application Support/org.pqrs/tmp/rootonly\" && sudo chmod 0700 \"/Library/Application Support/org.pqrs/tmp/rootonly\""
    fi

    # socket presence / stale check (warn only)
    if [ -e "/Library/Application Support/org.pqrs/tmp/rootonly/vhidd_server" ]; then
      if sudo lsof -nU 2>/dev/null | grep -q 'vhidd_server'; then
        ok "vhidd_server socket owner... in-use"
      else
        warn "vhidd_server socket present but not owned by an active process (stale)"
        warn "Rotate the socket and restart the daemon: sudo mv \"/Library/Application Support/org.pqrs/tmp/rootonly/vhidd_server\" \"/Library/Application Support/org.pqrs/tmp/rootonly/vhidd_server.bak.$(date -u +%s)\" && sudo launchctl kickstart -k system/org.pqrs.karabiner.vhiddaemon"
      fi
    fi
  else
    fail "VHID tmp dir missing: /Library/Application Support/org.pqrs/tmp/rootonly"
  fi

  # Driver ready event (recent)
  if sudo log show --predicate 'process == "virtual_hid_device_service"' --last 1h --info --debug | grep -q 'virtual_hid_keyboard_ready'; then
    ok "virtual_hid_keyboard_ready observed in last hour"
  else
    warn "no virtual_hid_keyboard_ready event in last hour (check driver Allow / reboot)"
  fi
fi

# Summary
echo "Summary"
if [ "$FAILED" = true ]; then
  echo "One or more checks failed — see messages above." >&2
  exit 1
else
  echo "All required checks passed (or returned warnings only)." 
  exit 0
fi
