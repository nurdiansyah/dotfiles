#!/bin/bash
# ============================================================================
# Dotfiles Setup Script
# ============================================================================
# Links dotfiles from ~/dotfiles to appropriate locations

set -e

DOTFILES_DIR="${HOME}/dotfiles"
BACKUP_DIR="${HOME}/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

echo "🔗 Setting up dotfiles symlinks..."
echo "📁 Backup directory: $BACKUP_DIR"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Helper function to safely symlink
symlink_file() {
  local src="$1"
  local dest="$2"
  local name=$(basename "$dest")
  
  if [[ ! -f "$src" ]]; then
    echo "⚠️  Source not found: $src"
    return 1
  fi
  
  if [[ -e "$dest" ]]; then
    if [[ -L "$dest" ]]; then
      echo "↻  Symlink already exists: $dest"
      return 0
    else
      echo "💾 Backing up: $dest → $BACKUP_DIR/$name"
      mv "$dest" "$BACKUP_DIR/$name"
    fi
  fi
  
  ln -s "$src" "$dest"
  echo "✓  Linked: $dest"
}

# Helper function to safely symlink directories
symlink_dir() {
  local src="$1"
  local dest="$2"
  local name=$(basename "$dest")
  
  if [[ ! -d "$src" ]]; then
    echo "⚠️  Source directory not found: $src"
    return 1
  fi
  
  if [[ -e "$dest" ]]; then
    if [[ -L "$dest" ]]; then
      echo "↻  Symlink already exists: $dest"
      return 0
    else
      echo "💾 Backing up: $dest → $BACKUP_DIR/$name"
      mv "$dest" "$BACKUP_DIR/$name"
    fi
  fi
  
  ln -s "$src" "$dest"
  echo "✓  Linked: $dest"
}

# ============================================================================
# ZSH Configuration
# ============================================================================
echo ""
echo "📝 Setting up ZSH..."

# Copy zsh files to home but keep dotfiles as source
if [[ -f "${DOTFILES_DIR}/zsh/.zshrc" ]]; then
  cp "${DOTFILES_DIR}/zsh/.zshrc" "${HOME}/.zshrc"
  echo "✓  Copied .zshrc"
fi

if [[ -f "${DOTFILES_DIR}/zsh/.zsh_profile" ]]; then
  cp "${DOTFILES_DIR}/zsh/.zsh_profile" "${HOME}/.zsh_profile"
  echo "✓  Copied .zsh_profile"
fi

# ============================================================================
# Neovim Configuration
# ============================================================================
echo ""
echo "🎨 Setting up Neovim..."

symlink_dir "${DOTFILES_DIR}/nvim" "${HOME}/.config/nvim"

# Create nvim state directory for profile switching
mkdir -p "${HOME}/.config/nvim/state"
echo "javascript" > "${HOME}/.config/nvim/state/profile"
echo "✓  Created nvim state directory with default profile"

# ============================================================================
# Git Configuration
# ============================================================================
echo ""
echo "🔑 Setting up Git..."

if [[ -f "${DOTFILES_DIR}/git/.gitconfig" ]]; then
  cp "${DOTFILES_DIR}/git/.gitconfig" "${HOME}/.gitconfig"
  echo "✓  Copied .gitconfig"
fi

if [[ -f "${DOTFILES_DIR}/git/.gitignore_global" ]]; then
  cp "${DOTFILES_DIR}/git/.gitignore_global" "${HOME}/.gitignore_global"
  echo "✓  Copied .gitignore_global"
fi

# ============================================================================
# Tmux Configuration (if exists)
# ============================================================================
if [[ -d "${DOTFILES_DIR}/tmux" ]]; then
  echo ""
  echo "⌨️  Setting up Tmux..."
  symlink_dir "${DOTFILES_DIR}/tmux" "${HOME}/.config/tmux"
fi

# ============================================================================
# Permissions & Reload
# ============================================================================
echo ""
echo "🔐 Setting permissions..."
chmod 600 "${HOME}/.zshrc" "${HOME}/.zsh_profile" 2>/dev/null || true
chmod 600 "${HOME}/.gitconfig" 2>/dev/null || true

echo ""
echo "✨ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "  1. Reload shell: exec zsh"
echo "  2. Set Nvim profile: nvim_profile {javascript|java|devops}"
echo "  3. Sync Nvim plugins: nvim +':Lazy sync'"
echo ""
echo "💡 Pro tips:"
echo "  • nvim_profile_show    → Show current profile"
echo "  • reload               → Reload shell config"
echo "  • nvim_format <file>   → Format file with conform"
echo ""

# ============================================================================
# Show backup location if created
# ============================================================================
if [[ "$(ls -A "$BACKUP_DIR")" ]]; then
  echo "📦 Backups saved to: $BACKUP_DIR"
else
  rmdir "$BACKUP_DIR" 2>/dev/null || true
fi
