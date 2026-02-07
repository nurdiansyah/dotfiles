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


## 🔄 Update

Untuk update zsh config dari dotfiles:

```bash
# Copy latest dari dotfiles (repo-managed)
cp ~/dotfiles/.zshrc ~/.zshrc
cp ~/dotfiles/.zsh_profile ~/.zsh_profile

# Reload
reload
```

## ✨ autosuggestions (git submodule)

`zsh-autosuggestions` is included as a git submodule at `zsh/autosuggestions`.

- If you are cloning this repository for the first time, initialize submodules:

```bash
git clone --recurse-submodules https://github.com/<your>/dotfiles.git
# or, after cloning:
git submodule update --init --recursive
```

- To add the submodule locally (already done in this repo):

```bash
git submodule add https://github.com/zsh-users/zsh-autosuggestions.git zsh/autosuggestions
```

- To update the submodule to the latest upstream commit:

```bash
git submodule update --remote --merge zsh/autosuggestions
```

- Enable `zsh-autosuggestions` in your shell by sourcing the shipped file from the submodule (recommended for this dotfiles layout):

```bash
echo 'source $HOME/dotfiles/zsh/autosuggestions/zsh-autosuggestions.zsh' >> ~/.zshrc
source ~/.zshrc
```

Notes:
- If you prefer `oh-my-zsh` plugin style, you can symlink or copy the submodule into `${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/` and then add `zsh-autosuggestions` to your `plugins=(...)` array.
- To remove the submodule cleanly, follow the standard git submodule removal steps (remove entry from `.gitmodules`, `git rm --cached` the path, and delete the directory).
