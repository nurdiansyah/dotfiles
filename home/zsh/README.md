# ZSH Configuration (moved)

Modern zsh configuration untuk dotfiles dengan profile switching & integration dengan Neovim.

## 📁 Struktur

```
home/zsh/
├── .zshrc           # Main zsh config (sourced by ~/.zshrc)
├── .zprofile        # Environment setup (login shells)
└── install.sh       # Setup script untuk link ke home directory
```

## 🎯 Fitur Utama

(See original documentation in root `zsh/README.md` — content migrated here for discoverability.)

## 🚀 Installation

```bash
cd ~/dotfiles/home/zsh
bash install.sh
```

Script akan:
1. ✅ Backup existing files ke `~/.dotfiles_backup_*`
2. ✅ Copy `.zshrc` ke `~/.zshrc`
3. ✅ Copy `.zsh_profile` atau `.zprofile` ke home
4. ✅ Symlink `nvim/` ke `~/.config/nvim`
5. ✅ Create `~/.config/nvim/state/` untuk profile switching
6. ✅ Set permissions

## 🔄 Update

Untuk update zsh config dari dotfiles:

```bash
# Copy latest dari dotfiles
cp ~/dotfiles/home/zsh/.zshrc ~/.zshrc
cp ~/dotfiles/home/zsh/.zsh_profile ~/.zsh_profile

# Reload
reload
```
