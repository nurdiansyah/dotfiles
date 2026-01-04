#!/usr/bin/env bash
# Kanata Removal Script
# Stops and removes the Kanata LaunchAgent

set -e

echo "🗑️  Kanata LaunchAgent Removal"
echo "=============================="
echo ""

PLIST_FILE="$HOME/Library/LaunchAgents/com.kanata.plist"

# Check if LaunchAgent exists
if [ ! -f "$PLIST_FILE" ]; then
    echo "ℹ️  LaunchAgent not found: $PLIST_FILE"
    echo "Nothing to remove."
    exit 0
fi

# Check if Kanata is running
if pgrep -x kanata > /dev/null; then
    echo "🛑 Stopping Kanata..."
    # Try to unload the LaunchAgent
    if launchctl unload "$PLIST_FILE" 2>/dev/null; then
        echo "✓ LaunchAgent unloaded"
    else
        echo "⚠️  Could not unload LaunchAgent, trying to kill process..."
        pkill -x kanata || true
    fi
    
    # Wait a moment
    sleep 1
    
    # Verify it stopped
    if pgrep -x kanata > /dev/null; then
        echo "⚠️  Warning: Kanata is still running"
        echo "You may need to manually kill it: pkill -9 kanata"
    else
        echo "✓ Kanata stopped"
    fi
else
    echo "ℹ️  Kanata is not running"
fi
echo ""

# Remove the plist file
echo "🗑️  Removing LaunchAgent plist..."
rm -f "$PLIST_FILE"
echo "✓ Removed: $PLIST_FILE"
echo ""

# Optionally remove logs
echo "📝 Log files:"
if [ -f /tmp/kanata.log ]; then
    LOG_SIZE=$(du -h /tmp/kanata.log | cut -f1)
    echo "  • /tmp/kanata.log ($LOG_SIZE)"
fi
if [ -f /tmp/kanata.err ]; then
    ERR_SIZE=$(du -h /tmp/kanata.err | cut -f1)
    echo "  • /tmp/kanata.err ($ERR_SIZE)"
fi

read -p "Remove log files? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -f /tmp/kanata.log /tmp/kanata.err
    echo "✓ Log files removed"
fi
echo ""

echo "✅ LaunchAgent Removed"
echo "====================="
echo ""
echo "Kanata LaunchAgent has been stopped and removed."
echo "Kanata will no longer start automatically at login."
echo ""
echo "Note: This does not uninstall Kanata from your system."
echo "To completely remove Kanata, edit darwin/configuration.nix"
echo "and remove 'kanata' from environment.systemPackages."
echo ""
echo "To restart the LaunchAgent later, run:"
echo "  ~/.dotfiles/kanata/setup-launchagent.sh"
echo ""
