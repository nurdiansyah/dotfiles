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

## 🚀 Installation (managed via Home Manager)

This repository uses Home Manager / nix-darwin to deploy user-level shell files. To apply the current `home/` configuration (including Zsh files and the default Neovim profile), run one of the following:

- macOS (nix-darwin):
```sh
sudo darwin-rebuild switch --flake .#macmini
```

- Standalone Home Manager (if not using nix-darwin):
```sh
nix run github:nix-community/home-manager#home-manager -- switch
# or: install to profile and run
nix profile install github:nix-community/home-manager
home-manager switch
```

Notes:
- The Neovim state file `~/.config/nvim/state/profile` is now created by Home Manager and defaults to `javascript`.
- The legacy `install.sh` script has been removed; use Home Manager to apply changes.


## 🔄 Update

Untuk update zsh config dari dotfiles:

```bash
# Copy latest dari dotfiles
cp ~/dotfiles/home/zsh/.zshrc ~/.zshrc
cp ~/dotfiles/home/zsh/.zsh_profile ~/.zsh_profile

# Reload
reload
```
