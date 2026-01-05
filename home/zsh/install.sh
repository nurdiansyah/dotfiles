#!/bin/bash
# ============================================================================
# Dotfiles Setup Script (Zsh)
# ============================================================================
# Links zsh dotfiles from repo to appropriate locations

set -e

DOTFILES_DIR="${HOME}/dotfiles" # repo root
# NOTE: zsh files moved to home/zsh for better discoverability

BACKUP_DIR="${HOME}/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

echo "🔗 Setting up ZSH dotfiles..."
echo "📁 Backup directory: $BACKUP_DIR"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Copy zsh files to home but keep dotfiles as source (now located in home/zsh)
if [[ -f "${DOTFILES_DIR}/home/zsh/.zshrc" ]]; then
  cp "${DOTFILES_DIR}/home/zsh/.zshrc" "${HOME}/.zshrc"
  echo "✓  Copied .zshrc"
fi

# Support both .zsh_profile (legacy) and .zprofile (preferred)
if [[ -f "${DOTFILES_DIR}/home/zsh/.zsh_profile" ]]; then
  cp "${DOTFILES_DIR}/home/zsh/.zsh_profile" "${HOME}/.zsh_profile"
  echo "✓  Copied .zsh_profile"
fi

if [[ -f "${DOTFILES_DIR}/home/zsh/.zprofile" ]]; then
  cp "${DOTFILES_DIR}/home/zsh/.zprofile" "${HOME}/.zprofile"
  echo "✓  Copied .zprofile"
fi

# Set permissions
chmod 600 "${HOME}/.zshrc" "${HOME}/.zsh_profile" 2>/dev/null || true

echo "✨ Zsh setup complete!"