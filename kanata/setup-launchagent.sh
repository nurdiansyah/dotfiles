#!/usr/bin/env bash
# Kanata LaunchAgent Setup Script
# Creates and loads a macOS LaunchAgent to run Kanata at startup

set -e

echo "🚀 Setting up Kanata LaunchAgent"
echo "================================"
echo ""

# Get the Kanata binary path
if ! which kanata &>/dev/null; then
    echo "❌ Error: Kanata not found in PATH"
    echo "Please install Kanata first (e.g. brew install kanata or use the repo bootstrap):"
    echo "  cd ~/dotfiles"
    echo "  ./install.sh"
    exit 1
fi

KANATA_BIN=$(which kanata)
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/kanata"
CONFIG_FILE="$CONFIG_DIR/kanata.kbd"
if [ ! -f "$CONFIG_FILE" ]; then
  if [ -f "$HOME/dotfiles/kanata/kanata.kbd" ]; then
    CONFIG_FILE="$HOME/dotfiles/kanata/kanata.kbd"
    echo "⚠ Using fallback config: $CONFIG_FILE"
  else
    echo "❌ Error: Config file not found: $CONFIG_FILE"
    echo "Hint: create a symlink with: bash $(dirname "$0")/link-config.sh"
    exit 1
  fi
fi
PLIST_FILE="$HOME/Library/LaunchAgents/com.kanata.plist"

echo "📍 Using Kanata binary: $KANATA_BIN"
echo "📍 Using config file: $CONFIG_FILE"
echo ""

# Verify config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Error: Config file not found: $CONFIG_FILE"
    exit 1
fi

# Verify config is valid
echo "🔍 Validating configuration..."
if ! kanata -c "$CONFIG_FILE" --check; then
    echo "❌ Error: Invalid configuration file"
    echo "Please fix the errors above and try again"
    exit 1
fi
echo "✓ Configuration is valid"
echo ""

# Create LaunchAgents directory if it doesn't exist
mkdir -p "$HOME/Library/LaunchAgents"

# Unload existing LaunchAgent if present
if [ -f "$PLIST_FILE" ]; then
    echo "🔄 Unloading existing LaunchAgent..."
    launchctl unload "$PLIST_FILE" 2>/dev/null || true
fi

# Create the LaunchAgent plist
echo "📝 Creating LaunchAgent plist..."
cat > "$PLIST_FILE" <<-PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.kanata</string>
    <key>ProgramArguments</key>
    <array>
        <string>${KANATA_BIN}</string>
        <string>-c</string>
        <string>${CONFIG_FILE}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/kanata.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/kanata.err</string>
    <key>ProcessType</key>
    <string>Interactive</string>
</dict>
</plist>
PLIST

echo "✓ LaunchAgent plist created: $PLIST_FILE"
echo ""

# Load the LaunchAgent
echo "🔄 Loading LaunchAgent..."
if launchctl load "$PLIST_FILE"; then
    echo "✓ LaunchAgent loaded successfully"
else
    echo "❌ Error: Failed to load LaunchAgent"
    echo "This may be due to missing permissions. Please:"
    echo "  1. Go to System Settings → Privacy & Security → Accessibility"
    echo "  2. Add your terminal application"
    echo "  3. Run this script again"
    exit 1
fi
echo ""

# Wait a moment for Kanata to start
sleep 2

# Check if Kanata is running
echo "🔍 Verifying Kanata is running..."
if pgrep -x kanata > /dev/null; then
    echo "✓ Kanata is running!"
    echo ""
    echo "📊 Process info:"
    ps aux | grep "[k]anata" | head -1
else
    echo "⚠️  Warning: Kanata doesn't appear to be running"
    echo "Check the logs for errors:"
    echo "  tail -f /tmp/kanata.log"
    echo "  tail -f /tmp/kanata.err"
fi
echo ""

echo "✅ Setup Complete!"
echo "=================="
echo ""
echo "Kanata will now start automatically when you log in."
echo ""
echo "Useful commands:"
echo "  • Check status:  launchctl list | grep kanata"
echo "  • View logs:     tail -f /tmp/kanata.log"
echo "  • Stop service:  launchctl unload $PLIST_FILE"
echo "  • Start service: launchctl load $PLIST_FILE"
echo ""
echo "🧪 Test your setup:"
echo "  1. Tap Caps Lock → should be Escape"
echo "  2. Hold Caps Lock + H/J/K/L → should be arrow keys"
echo ""
