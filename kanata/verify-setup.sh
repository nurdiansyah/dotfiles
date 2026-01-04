#!/usr/bin/env bash
# Kanata Setup Verification Script
# Run this after installing Kanata via Nix Darwin

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
check "Config directory" "[ -d ~/.dotfiles/kanata ]"
check "Main config" "[ -f ~/.dotfiles/kanata/kanata.kbd ]"
check "README" "[ -f ~/.dotfiles/kanata/README.md ]"
check "Quick Start" "[ -f ~/.dotfiles/kanata/QUICKSTART.md ]"
check "macOS Install Guide" "[ -f ~/.dotfiles/kanata/INSTALL-MACOS.md ]"
check "Examples" "[ -f ~/.dotfiles/kanata/examples.kbd ]"

echo ""
echo "✅ Configuration Validation"
echo "--------------------------"
if which kanata &>/dev/null; then
    if kanata -c ~/.dotfiles/kanata/kanata.kbd --check &>/dev/null; then
        echo -e "Config syntax... ${GREEN}✓${NC}"
    else
        echo -e "Config syntax... ${RED}✗${NC}"
        echo "Run: kanata -c ~/.dotfiles/kanata/kanata.kbd --check"
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

echo ""
echo "🚀 Service Setup (Optional)"
echo "--------------------------"
check "LaunchAgent file" "[ -f ~/Library/LaunchAgents/com.kanata.plist ]" true
if [ -f ~/Library/LaunchAgents/com.kanata.plist ]; then
    check "LaunchAgent loaded" "launchctl list | grep -q kanata" true
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
    echo "  1. Read: cat ~/.dotfiles/kanata/QUICKSTART.md"
    echo "  2. Start: kanata -c ~/.dotfiles/kanata/kanata.kbd"
    echo "  3. Test: Tap Caps Lock (should be Escape)"
    echo ""
else
    echo -e "${RED}✗ Some checks failed.${NC}"
    echo ""
    echo "Please review the failures above and:"
    echo "  1. Ensure Nix Darwin is installed and configured"
    echo "  2. Run: darwin-rebuild switch --flake ~/.dotfiles#macmini"
    echo "  3. Check installation guide: ~/.dotfiles/kanata/INSTALL-MACOS.md"
    echo ""
fi

exit 0
