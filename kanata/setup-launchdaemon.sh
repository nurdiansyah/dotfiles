#!/usr/bin/env bash
# Kanata LaunchDaemon Setup Script (system-wide, runs as root)
# Installs LaunchDaemon plist to /Library/LaunchDaemons and places config in
# /Library/Application Support/kanata/kanata.kbd (creates it from repo if needed)

set -euo pipefail

PLIST_NAME="org.nurdiansyah.kanata.plist"
PLIST_SRC="$(dirname "$0")/org.nurdiansyah.kanata.plist"
PLIST_DST="/Library/LaunchDaemons/${PLIST_NAME}"
KADATA_DIR="/Library/Application Support/kanata"
KADATA_CONF="${KADATA_DIR}/kanata.kbd"
KANATA_BIN="$(command -v kanata || true)"

if [ "$EUID" -ne 0 ]; then
  echo "❌ This script must be run as root (sudo)."
  echo "  sudo $0"
  exit 1
fi

if [ -z "$KANATA_BIN" ]; then
  echo "❌ Error: 'kanata' binary not found in PATH for root."
  echo "Install kanata (Homebrew) and ensure root can see it, or set KANATA_BIN environment variable."
  echo "Example: sudo env PATH=$PATH $0"
  exit 1
fi

echo "🚀 Installing Kanata LaunchDaemon (system-wide)"
echo "PLIST: $PLIST_DST"
echo "Config: $KADATA_CONF"

# Create destination directories
mkdir -p "$KADATA_DIR"
chown root:wheel "$KADATA_DIR"
chmod 0755 "$KADATA_DIR"

# Copy config if missing (use repo config as source if present)
REPO_CONF="$HOME/dotfiles/kanata/kanata.kbd"
if [ ! -f "$KADATA_CONF" ]; then
  if [ -f "$REPO_CONF" ]; then
    echo "ℹ️ Copying repo config to $KADATA_CONF"
    cp "$REPO_CONF" "$KADATA_CONF"
    chown root:wheel "$KADATA_CONF"
    chmod 0644 "$KADATA_CONF"
  else
    echo "⚠️ Warning: No config found at $REPO_CONF and $KADATA_CONF missing." 
    echo "Please place a config at $KADATA_CONF or at $REPO_CONF and re-run this script."
    # proceed, but the daemon will not start correctly until config exists
  fi
else
  echo "✓ System config exists: $KADATA_CONF"
fi

# Additional vars
PLIST_DIR="/Library/LaunchDaemons"
KANATA_CONFIG="$KADATA_CONF"
KANATA_PORT="${KANATA_PORT:-}"

# Ensure Plist dir exists
mkdir -p "$PLIST_DIR"

# 2. Install Kanata via Homebrew if not present (best-effort)
if ! command -v kanata >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1 && [ -n "${SUDO_USER:-}" ]; then
    echo "ℹ️ 'kanata' not found; attempting to install via brew as the invoking user ($SUDO_USER)..."
    sudo -u "$SUDO_USER" brew list kanata >/dev/null 2>&1 || sudo -u "$SUDO_USER" brew install kanata || true
  else
    echo "⚠️ 'kanata' not found in PATH for root. Please install Kanata (Homebrew) or run this script with your PATH preserved:"
    echo "  sudo env PATH=\"$PATH\" $0"
  fi
  KANATA_BIN="$(command -v kanata || echo '')"
fi

# 3. Write plist files
KANATA_BIN="${KANATA_BIN:-$(command -v kanata || echo /usr/local/bin/kanata)}"

# Kanata daemon (system)
cat > "${PLIST_DIR}/org.nurdiansyah.kanata.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>org.nurdiansyah.kanata</string>
  <key>ProgramArguments</key><array>
    <string>${KANATA_BIN}</string>
    <string>-c</string><string>${KANATA_CONFIG}</string>
EOF

if [ -n "$KANATA_PORT" ]; then
cat >> "${PLIST_DIR}/org.nurdiansyah.kanata.plist" <<EOF
    <string>--port</string><string>${KANATA_PORT}</string>
EOF
fi
cat >> "${PLIST_DIR}/org.nurdiansyah.kanata.plist" <<'EOF'
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>/var/log/kanata.log</string>
  <key>StandardErrorPath</key><string>/var/log/kanata.err</string>
</dict></plist>
EOF
chown root:wheel "${PLIST_DIR}/org.nurdiansyah.kanata.plist"
chmod 0644 "${PLIST_DIR}/org.nurdiansyah.kanata.plist"

# Karabiner VHID daemon
cat > "${PLIST_DIR}/org.pqrs.karabiner.vhiddaemon.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>org.pqrs.karabiner.vhiddaemon</string>
  <key>ProgramArguments</key><array>
    <string>/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
</dict></plist>
EOF
chown root:wheel "${PLIST_DIR}/org.pqrs.karabiner.vhiddaemon.plist"
chmod 0644 "${PLIST_DIR}/org.pqrs.karabiner.vhiddaemon.plist"

# Karabiner VHID manager
cat > "${PLIST_DIR}/org.pqrs.karabiner.vhidmanager.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>org.pqrs.karabiner.vhidmanager</string>
  <key>ProgramArguments</key><array>
    <string>/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager</string>
    <string>activate</string>
  </array>
  <key>RunAtLoad</key><true/>
</dict></plist>
EOF
chown root:wheel "${PLIST_DIR}/org.pqrs.karabiner.vhidmanager.plist"
chmod 0644 "${PLIST_DIR}/org.pqrs.karabiner.vhidmanager.plist"

# 4. Bootstrap and enable services
# Kanata
echo "🔄 Bootstrapping org.nurdiansyah.kanata"
launchctl bootout system "${PLIST_DIR}/org.nurdiansyah.kanata.plist" 2>/dev/null || true
launchctl bootstrap system "${PLIST_DIR}/org.nurdiansyah.kanata.plist"
launchctl enable system/org.nurdiansyah.kanata || true

# Karabiner-VHIDDaemon
echo "🔄 Bootstrapping org.pqrs.karabiner.vhiddaemon"
launchctl bootout system "${PLIST_DIR}/org.pqrs.karabiner.vhiddaemon.plist" 2>/dev/null || true
launchctl bootstrap system "${PLIST_DIR}/org.pqrs.karabiner.vhiddaemon.plist"
launchctl enable system/org.pqrs.karabiner.vhiddaemon || true

# Karabiner-VHIDManager
echo "🔄 Bootstrapping org.pqrs.karabiner.vhidmanager"
launchctl bootout system "${PLIST_DIR}/org.pqrs.karabiner.vhidmanager.plist" 2>/dev/null || true
launchctl bootstrap system "${PLIST_DIR}/org.pqrs.karabiner.vhidmanager.plist"
launchctl enable system/org.pqrs.karabiner.vhidmanager || true

# 5. Prompt for permissions
read -rp "Press Enter to open System Settings → Privacy & Security to allow Karabiner system extension (if needed)..."
open "x-apple.systempreferences:com.apple.LoginItems-Settings.extension" || true
read -rp "Press Enter once you've approved the extension..."

read -rp "Press Enter to open Accessibility settings to add Kanata (if needed)..."
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" || true
read -rp "Press Enter once you're done..."

read -rp "Press Enter to open Input Monitoring settings to add Kanata (if needed)..."
open "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent" || true
read -rp "Press Enter once you're done..."

# Wait briefly and check status
sleep 1
if pgrep -x kanata > /dev/null; then
  echo "✓ Kanata process running (system daemon)"
else
  echo "⚠️ Kanata doesn't appear to be running yet. Check logs: /var/log/kanata.log /var/log/kanata.err"
fi

echo "✅ Installation complete."
echo "Useful commands:"
echo "  sudo launchctl print system/${PLIST_NAME}"
echo "  sudo launchctl bootout system ${PLIST_DST}   # unload"

exit 0
