#!/usr/bin/env bash
# ============================================================================
# Nix Darwin & Home Manager Installation Script
# Supports multiple machines: macbook, macmini
# ============================================================================

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOTFILES_DIR="${SCRIPT_DIR}"

echo "🔧 Installing Nix Darwin + Home Manager Configuration"
echo "📁 Dotfiles directory: $DOTFILES_DIR"
echo ""

# ============================================================================
# Detect or prompt for machine type
# ============================================================================
HOSTNAME=$(hostname)
MACHINE_TYPE=""

if [[ "$HOSTNAME" == *"MacBook"* ]] || [[ "$HOSTNAME" == *"mbp"* ]]; then
  MACHINE_TYPE="macbook"
  echo "📱 Detected MacBook"
elif [[ "$HOSTNAME" == *"MacMini"* ]] || [[ "$HOSTNAME" == *"mini"* ]]; then
  MACHINE_TYPE="macmini"
  echo "🖥️  Detected Mac Mini"
fi

# If not detected, ask user
if [[ -z "$MACHINE_TYPE" ]]; then
  echo "Machine type not automatically detected."
  echo ""
  echo "Which machine are you configuring?"
  echo "  1) macbook - MacBook Air/Pro"
  echo "  2) macmini - Mac Mini"
  echo ""
  read -p "Enter choice (1-2): " choice
  
  case "$choice" in
    1) MACHINE_TYPE="macbook" ;;
    2) MACHINE_TYPE="macmini" ;;
    *) echo "❌ Invalid choice"; exit 1 ;;
  esac
fi

echo "Using machine type: $MACHINE_TYPE"
echo ""

# ============================================================================
# Check if Nix is installed
# ============================================================================
if ! command -v nix &> /dev/null; then
  echo "❌ Nix is not installed!"
  echo "📥 Installing Nix..."
  
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS installation
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  else
    echo "❌ This script is for macOS only"
    exit 1
  fi
else
  echo "✓ Nix is installed: $(nix --version)"
fi

echo ""

# ============================================================================
# Enable Flakes
# ============================================================================
echo "🔧 Enabling Nix flakes..."

mkdir -p ~/.config/nix
cat > ~/.config/nix/nix.conf <<EOF
experimental-features = nix-command flakes
EOF

echo "✓ Flakes enabled"
echo ""

# ============================================================================
# Initialize Nix Darwin
# ============================================================================
if ! command -v darwin-rebuild &> /dev/null; then
  echo "📦 Initializing Nix Darwin..."
  
  nix run nix-darwin -- switch --flake "$DOTFILES_DIR#default"
  
  echo "✓ Nix Darwin initialized"
else
  echo "✓ darwin-rebuild is already available"
fi

echo ""

# ============================================================================
# Apply Configuration
# ============================================================================
echo "🚀 Applying Nix Darwin configuration for: $MACHINE_TYPE"

darwin-rebuild switch --flake "$DOTFILES_DIR#$MACHINE_TYPE"

echo ""
echo "✨ Configuration applied successfully!"
echo ""

# ============================================================================
# Next Steps
# ============================================================================
echo "📋 Next steps:"
echo "  1. Reload shell: exec zsh"
echo "  2. Set Nvim profile: nvim_profile {javascript|java|devops}"
echo "  3. Verify: darwin-rebuild check --flake $DOTFILES_DIR#$MACHINE_TYPE"
echo ""
echo "💡 Useful commands:"
echo "  darwin-rebuild switch --flake $DOTFILES_DIR#$MACHINE_TYPE       # Apply changes"
echo "  darwin-rebuild check --flake $DOTFILES_DIR#$MACHINE_TYPE        # Check for errors"
echo "  darwin-rebuild switch --flake $DOTFILES_DIR#macbook             # Switch to macbook"
echo "  darwin-rebuild switch --flake $DOTFILES_DIR#macmini             # Switch to macmini"
echo "  nix flake update                                                 # Update inputs"
echo "  home-manager switch --flake $DOTFILES_DIR#$MACHINE_TYPE          # Update home-manager"
echo ""
echo "📚 Documentation:"
echo "  - Nix Darwin: https://github.com/lnl7/nix-darwin"
echo "  - Home Manager: https://nix-community.github.io/home-manager/"
echo "  - Nixpkgs: https://search.nixos.org/packages"
echo ""
