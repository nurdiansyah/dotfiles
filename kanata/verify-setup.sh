#!/usr/bin/env bash
# Kanata Setup Verification Script
# Run this after installing Kanata (Homebrew/binary or repo bootstrap)

set -e

echo "🔍 Kanata Installation Verification"
echo "===================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track status
ALL_PASSED=true

# Function to check and report
check() {
  local name="$1"
  local command="$2"
  local optional="${3:-false}"

  echo -n "Checking $name... "

  if eval "$command" &>/dev/null; then
    echo -e "${GREEN}✓${NC}"
    return 0
  else
    if [ "$optional" = "true" ]; then
      echo -e "${YELLOW}⚠ (optional)${NC}"
      return 0
    else
      echo -e "${RED}✗${NC}"
      ALL_PASSED=false
      return 1
    fi
  fi
}

echo "📦 Package Installation"
echo "----------------------"
check "Kanata binary" "which kanata"
check "Kanata version" "kanata --version"

echo ""
echo "📁 Configuration Files"
echo "---------------------"
check "Config dir (XDG)" "[ -d ${XDG_CONFIG_HOME:-$HOME/.config}/kanata ]" true
check "Config dir (dotfiles)" "[ -d $HOME/dotfiles/kanata ]" true
check "Main config (XDG)" "[ -f ${XDG_CONFIG_HOME:-$HOME/.config}/kanata/kanata.kbd ]" true
check "Main config (dotfiles)" "[ -f $HOME/dotfiles/kanata/kanata.kbd ]" true
check "README" "[ -f $HOME/dotfiles/kanata/README.md ]" true
check "Quick Start" "[ -f $HOME/dotfiles/kanata/QUICKSTART.md ]" true
check "macOS Install Guide" "[ -f $HOME/dotfiles/kanata/INSTALL-MACOS.md ]" true
check "Examples" "[ -f $HOME/dotfiles/kanata/examples.kbd ]" true

echo ""
echo "✅ Configuration Validation"
echo "--------------------------"
if which kanata &>/dev/null; then
  # prefer XDG config, fallback to dotfiles
  if [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/kanata/kanata.kbd" ] && kanata -c "${XDG_CONFIG_HOME:-$HOME/.config}/kanata/kanata.kbd" --check &>/dev/null; then
    echo -e "Config syntax... ${GREEN}✓${NC}"
  elif [ -f "$HOME/dotfiles/kanata/kanata.kbd" ] && kanata -c "$HOME/dotfiles/kanata/kanata.kbd" --check &>/dev/null; then
    echo -e "Config syntax (fallback)... ${GREEN}✓${NC}"
  else
    echo -e "Config syntax... ${RED}✗${NC}"
    echo "Run: kanata -c ~/.config/kanata/kanata.kbd --check"
    ALL_PASSED=false
  fi
else
  echo -e "Config syntax... ${YELLOW}⚠ (kanata not in PATH)${NC}"
fi

echo ""
echo "🔐 macOS Permissions (Manual Check Required)"
echo "-------------------------------------------"
echo "Please verify manually:"
echo "  1. System Settings → Privacy & Security → Accessibility"
echo "     ↳ Your terminal app should be listed and enabled"
echo "  2. System Settings → Privacy & Security → Input Monitoring"
echo "     ↳ Your terminal app should be listed and enabled"

echo "🔌 Karabiner DriverKit"
echo "----------------------"
if command -v systemextensionsctl >/dev/null 2>&1; then
  if systemextensionsctl list | grep -i 'org.pqrs.Karabiner-DriverKit-VirtualHIDDevice' >/dev/null 2>&1; then
    echo -e "Karabiner DriverKit... ${GREEN}✓${NC}"

    # Runtime activity check: look for recent virtual_hid_device_service "ready" events
    if command -v log >/dev/null 2>&1; then
      if sudo log show --predicate 'process == "virtual_hid_device_service"' --last 1h --info --debug | grep -q 'virtual_hid_keyboard_ready'; then
        echo -e "virtual_hid_device_service activity... ${GREEN}✓${NC}"
      else
        echo -e "virtual_hid_device_service activity... ${YELLOW}⚠ (no recent ready event)${NC}"
        echo "Run: sudo log show --predicate 'process == \"virtual_hid_device_service\"' --last 1h --info --debug | tail -n 50"
        ALL_PASSED=false
      fi
    else
      echo -e "log... ${YELLOW}⚠ (not available)${NC}"
    fi

  else
    echo -e "Karabiner DriverKit... ${RED}✗${NC}"
    echo "Run: systemextensionsctl list | grep -i karabiner -A2"
    ALL_PASSED=false
  fi
else
  echo -e "systemextensionsctl... ${YELLOW}⚠ (not available)${NC}"
  echo "On older macOS, check the Karabiner driver in System Settings → Privacy & Security"
fi

# --- VHID / vhidd_server checks (macOS-specific, actionable) ---
# These help surface the common "Permission denied" error when the VHID
# socket is under a root-only directory and Kanata is run as a non-root user.
if sudo test -d "/Library/Application Support/org.pqrs/tmp/rootonly" >/dev/null 2>&1; then
  perms=$(sudo stat -f '%OLp %Su:%Sg' "/Library/Application Support/org.pqrs/tmp/rootonly" 2>/dev/null || true)
  if [ "${perms:-}" = "0700 root:wheel" ]; then
    echo -e "VHID tmp dir permissions... ${GREEN}✓${NC}"
  else
    echo -e "VHID tmp dir permissions... ${YELLOW}⚠${NC}"
    echo "Run: sudo chown root:wheel \"/Library/Application Support/org.pqrs/tmp/rootonly\" && sudo chmod 0700 \"/Library/Application Support/org.pqrs/tmp/rootonly\""
    ALL_PASSED=false
  fi
else
  echo -e "VHID tmp dir... ${YELLOW}⚠ (missing)${NC}"
  echo "If DriverKit is installed the dir will be created when the VHID daemon runs; try: sudo launchctl kickstart -k system/org.pqrs.karabiner.vhiddaemon"
  ALL_PASSED=false
fi

# Check for a stale or unowned vhidd socket
if [ -e "/Library/Application Support/org.pqrs/tmp/rootonly/vhidd_server" ]; then
  if sudo lsof -nU 2>/dev/null | grep -q 'vhidd_server'; then
    echo -e "vhidd_server socket owner... ${GREEN}✓${NC}"
  else
    echo -e "vhidd_server socket... ${YELLOW}⚠ (stale / no owner)${NC}"
    echo "Rotate the socket and restart the daemon:"
    echo "  sudo mv \"/Library/Application Support/org.pqrs/tmp/rootonly/vhidd_server\" \"/Library/Application Support/org.pqrs/tmp/rootonly/vhidd_server.bak.$(date -u +%s)\""
    echo "  sudo launchctl kickstart -k system/org.pqrs.karabiner.vhiddaemon"
    ALL_PASSED=false
  fi
fi

# Check helper plists for Karabiner VHID
check "Karabiner VHID LaunchDaemon" "[ -f /Library/LaunchDaemons/org.pqrs.karabiner.vhiddaemon.plist ]" true
if [ -f /Library/LaunchDaemons/org.pqrs.karabiner.vhiddaemon.plist ]; then
  check "Karabiner VHID loaded" "sudo launchctl print system/org.pqrs.karabiner.vhiddaemon >/dev/null 2>&1" true
fi

# Security note
echo ""
echo "⚠️ Security: do NOT make /Library/Application Support/org.pqrs/tmp/rootonly world-readable on multi-user machines; run Kanata as root (LaunchDaemon) instead."

echo ""
echo "🚀 Service Setup (Optional)"
echo "--------------------------"
check "LaunchAgent file" "[ -f ~/Library/LaunchAgents/com.kanata.plist ]" true
check "LaunchDaemon file" "[ -f /Library/LaunchDaemons/org.nurdiansyah.kanata.plist ]" true
if [ -f /Library/LaunchDaemons/org.nurdiansyah.kanata.plist ]; then
  check "LaunchDaemon loaded" "sudo launchctl print system/org.nurdiansyah.kanata >/dev/null 2>&1" true
fi

echo ""
echo "📊 Summary"
echo "=========="
if [ "$ALL_PASSED" = true ]; then
  echo -e "${GREEN}✓ All checks passed!${NC}"
  echo ""
  echo "🎉 Kanata is ready to use!"
  echo ""
  echo "Quick start:"
  echo "  1. Read: cat ~/.config/kanata/QUICKSTART.md"
  echo "  2. Start: kanata -c ~/.config/kanata/kanata.kbd"
  echo "  3. Test: Tap Caps Lock (should be Escape)"
  echo ""
else
  echo -e "${RED}✗ Some checks failed.${NC}"
  echo ""
  echo "Please review the failures above and:"
  echo "  1. Ensure Kanata is installed and in PATH (e.g., via Homebrew or a binary in PATH)"
  echo "  2. Check installation guide: ~/.config/kanata/INSTALL-MACOS.md"
  echo ""
fi

exit 0
