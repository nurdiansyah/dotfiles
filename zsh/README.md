# ZSH Configuration (migrated)

Modern zsh configuration for dotfiles with profile switching & integration with Neovim.

## 📁 Struktur (ringkas)

```
./                 # repo root
├── .zshrc         # Consolidated shell config (copy/source this into your $HOME)
├── .zprofile      # Environment setup for login shells
├── init.zsh.bak   # (backup) previous `init.zsh` moved during migration (archived)
└── README.md      # This file
```

Note: the active, canonical zsh config is now `./.zshrc` at the repo root — keep this file under version control and source/copy it to your home directory to apply changes.

## 🎯 Fitur Utama

(See original documentation in root `zsh/README.md` — content migrated here for discoverability.)

## 🚀 Installation / Usage

You can apply the repo `.zshrc` by copying or sourcing it into your home directory. Two common options:

1) Copy the file (persistent):

```bash
cp ~/dotfiles/.zshrc ~/.zshrc
# then reload your shell
source ~/.zshrc
```

2) Source it from your existing `~/.zshrc` (recommended if you keep local customizations):

```bash
# Add to your ~/.zshrc if not present
if [ -f "$HOME/dotfiles/.zshrc" ]; then
  source "$HOME/dotfiles/.zshrc"
fi
# then reload
source ~/.zshrc
```

Notes:
- A previous `init.zsh` file was migrated into the consolidated `./.zshrc`; a backup is available in the repository history if needed.
- The canonical shell config for this repo is `./.zshrc`. Copy or source it to your home directory to apply the repo config (see usage step above).

## 🔧 Znap support (optional)

This repository includes lightweight support for [Znap](https://github.com/marlonrichert/zsh-snap).
The top of `./.zshrc` will clone Znap into `~/.local/znap` and source it to enable plugin management.

If you prefer to manage plugins with **Znap** instead of using the bundled git submodules, you can run the included helper after starting a new shell:

```sh
# Register & (attempt to) install known plugins via Znap
zsh_znap_install_plugins
```

`zsh_znap_install_plugins` will attempt to register and install recommended plugins (for example: `marlonrichert/zsh-autocomplete` and `zsh-users/zsh-autosuggestions`). If Znap isn't available or you prefer the repo-provided copies, the dotfiles will continue to fallback and source the bundled plugin files automatically.


## 🔄 Update

Untuk update zsh config dari dotfiles:

```bash
# Copy latest dari dotfiles (repo-managed)
cp ~/dotfiles/.zshrc ~/.zshrc
cp ~/dotfiles/.zsh_profile ~/.zsh_profile

# Reload
reload
```

## ✨ autosuggestions (previously bundled)

`zsh-autosuggestions` is no longer included in this repository. We recommend installing it via a plugin manager or package manager.

- Install via Znap (recommended with this dotfiles layout):

```bash
# Use the helper after sourcing ~/.zshrc, or run directly
zsh_znap_install_plugins
# or register & install manually
znap source zsh-users/zsh-autosuggestions && znap install zsh-users/zsh-autosuggestions
```

- Install with Homebrew / Nix / package manager if available, or clone manually:

```bash
# Homebrew (example)
brew install zsh-autosuggestions
# Manual (clone and source)
git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git ~/.local/zsh-autosuggestions
echo 'source $HOME/.local/zsh-autosuggestions/zsh-autosuggestions.zsh' >> ~/.zshrc
```

If you relied on the bundled copies in this repo, they have been removed in favor of managing plugins with Znap or your preferred manager.

## ✨ autocomplete (previously bundled)

`zsh-autocomplete` is no longer included in this repository. Prefer installing it via Znap or a package manager.

- Install via Znap (recommended with this dotfiles layout):

```bash
zsh_znap_install_plugins
# or
znap source marlonrichert/zsh-autocomplete && znap install marlonrichert/zsh-autocomplete
```

- Or install with your package manager or clone manually:

```bash
# Manual (clone and source)
git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git ~/.local/zsh-autocomplete
echo 'source $HOME/.local/zsh-autocomplete/zsh-autocomplete.plugin.zsh' >> ~/.zshrc
```

If you used the repo-bundled copy before, it is now removed in favor of external plugin management.

Notes:
- Remove any calls to `compinit` from your `.zshrc` (the plugin handles compinit itself).
- When using Ubuntu, add `skip_global_compinit=1` to your `.zshenv` if needed.
