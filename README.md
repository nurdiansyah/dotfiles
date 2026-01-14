# Dotfiles

Personal configuration files for macOS development environment.

## Structure

```
dotfiles/
├── nvim/           -- Neovim config (profile-based plugins)
├── zsh/            -- Zsh shell config
├── tmux/           -- Tmux configuration
├── git/            -- Git config
├── kanata/         -- Kanata keyboard remapper config
├── install.sh      -- Setup installer
└── README.md       -- This file
```

## Quick Setup

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 2. Install Dependencies

This repository prefers using the `Brewfile` to manage Homebrew installs. The installer supports applying the repo `Brewfile`, bootstrapping `hererocks`, and installing a small set of helper packages.

Note: invoking a subcommand (for example `./install.sh config`) will not trigger the interactive "install core" prompt; subcommands are treated as explicit actions. To perform the recommended core install non-interactively, use `./install.sh --all` or pass `--yes` to skip confirmations.

Example (fully non-interactive bootstrap):

```bash
./install.sh --all --yes
```


Common usage:

```bash
chmod +x install.sh
# Use the repository Brewfile (recommended)
./install.sh --brewfile

# Install packages from repo Brewfile and also ensure npm global language servers
./install.sh --brewfile --npm-globals

# On macOS: disable press-and-hold to enable key repeat (opt-in)
./install.sh --enable-macos-key-repeat  # add --yes to skip the confirmation prompt
```

Advanced options:

- `--update-brewfile` — if you request packages not present in the repo `Brewfile`, append them to the `Brewfile` (creates a timestamped backup). Use this when you want the `Brewfile` to be updated automatically.
- `--commit-brewfile` — use together with `--update-brewfile` to automatically commit the appended changes (requires `git` and will create a backup prior to committing).
- `--dry-run` — perform a dry run of Brew operations (prints actions without executing). This uses the helper script `scripts/brew-install.sh --dry-run` under the hood; you can call that script directly for advanced workflows.

Direct use: `scripts/brew-install.sh`

For advanced or programmatic workflows you can call the helper directly. It supports the same options plus a `--file <path>` override and prints machine-readable markers so callers can parse results.

Examples:

```bash
# Dry-run (safe; prints actions and BREW-INFO markers)
./scripts/brew-install.sh --dry-run git curl

# Append missing packages and commit (creates a backup first)
./scripts/brew-install.sh --update --commit git node

# Run bundle for a specific Brewfile
./scripts/brew-install.sh --file /path/to/Brewfile
```

Notes:

- The script emits lines prefixed with `BREW-INFO:` that indicate important events: `USED <file>`, `APPENDED <pkgs>`, `BACKUP <path>`, and `COMMIT <sha>`.
- When using `--commit` the script requires `git` and will create a timestamped backup before modifying the Brewfile; prefer committing from a branch and opening a PR for review.
- `--dry-run` — perform a dry run of Brew operations (prints actions without executing). This uses the new helper `scripts/brew-install.sh --dry-run` under the hood; you can call that script directly for advanced usage.

The installer will:
- Prefer installing via the repository `Brewfile` (or a temporary Brewfile generated from requested packages),
- Bootstrap Lua 5.1 via `hererocks` (for Neovim plugin support),
- Optionally install npm global packages used by language servers (when `--npm-globals` is passed),
- Report which Brewfile was used and any packages appended/committed.

### macOS preferences

- `--enable-macos-key-repeat` — Disable the press-and-hold accent menu and enable key repeat system-wide on macOS. This setting is **opt-in**: pass the flag to apply the change; the installer will prompt for confirmation unless `--yes` is also provided. To verify the setting, run:

```bash
defaults read -g ApplePressAndHoldEnabled
```

A value of `0`/`false` indicates key repeat is enabled; restarting affected apps (or logging out/in) may be required for the change to take effect.

### hererocks & PEP 668

Note: Recent Python distributions enforce PEP 668 ("externally-managed environment"), which will prevent `python3 -m pip install --user ...` from working on some systems (you will see an "externally-managed-environment" error). The installer handles this by prompting you before performing any system-level changes and by providing safe fallbacks.

Recommended behaviors and commands:

- Preferred: Install `pipx` and use it to install `hererocks` (isolated, no system-wide changes):

```bash
brew install pipx
pipx install hererocks
python3 -m hererocks "$HOME/.local/share/nvim/lazy-rocks/hererocks" --lua=5.1
```

- Fallback: Use a temporary virtual environment (no system changes):

```bash
python3 -m venv /tmp/hererocks-venv
source /tmp/hererocks-venv/bin/activate
pip install hererocks
python3 -m hererocks "$HOME/.local/share/nvim/lazy-rocks/hererocks" --lua=5.1
deactivate
```

The installer (`./install.sh --hererocks`) will prompt and provide instructions for installing `pipx`; it will not auto-install `pipx` for you, and will offer to use a temporary `venv` as a fallback. Recent updates also add automatic handling for PEP 668: when `python3 -m pip install --user ...` is blocked by an "externally-managed environment", the installer will create a per-package virtual environment under `${XDG_DATA_HOME:-$HOME/.local/share}/venvs/<pkg>` and install the package there (e.g., `pynvim`), then print instructions to set `g:python3_host_prog` for Neovim. You can also use the helper script `scripts/bootstrap_hererocks.sh` which supports `--yes`, `--use-pipx`, and `--use-venv` for non-interactive or explicit modes. Avoid passing `--break-system-packages` to `pip` unless you understand the risks and explicitly opt in.

### Safety checklist: updating the repository `Brewfile`

If you plan to append packages to the repo `Brewfile` and commit them automatically, follow this safe workflow:

1. Run the updater without committing to see what would be added (creates a timestamped backup):

```bash
./install.sh --update-brewfile
# Inspect the changes
git diff Brewfile
```

2. Test the updated Brewfile locally (optional but recommended):

```bash
# Run a bundle from the updated Brewfile (already done by the installer), or run manual checks
brew bundle --file=Brewfile --verbose
```

3. If everything looks good, either commit manually or use the automatic commit option:

```bash
# Manual commit (preferred for review):
git checkout -b update/brewfile-<date>
git add Brewfile
git commit -m "chore(brewfile): add <pkg1> <pkg2>"
git push -u origin update/brewfile-<date>
# or automated commit (script makes a backup before committing):
./install.sh --update-brewfile --commit-brewfile
```

4. Open a normal pull request for review and CI to validate the changes.

Notes:
- The script creates a backup named `Brewfile.bak.<UTC timestamp>` before appending packages; if a commit fails, you can restore from that backup.
- Prefer making updates on a branch and opening a PR so that collaborators can review package additions.

### 3. Create Symlinks

```bash
# Neovim
ln -s ~/dotfiles/nvim ~/.config/nvim

# Zsh (optional)
# ln -s ~/dotfiles/home/zsh ~/.config/zsh

# Git (optional)
# ln -s ~/dotfiles/git ~/.config/git
```

### 4. First Launch

```bash
nvim
```

Plugins will auto-install on first launch. This may take a few minutes.

## Neovim

Profile-based Neovim configuration with support for JavaScript/TypeScript and DevOps workflows.

- **Colorscheme**: Tokyonight
- **Plugin Manager**: lazy.nvim
- **LSP**: mason + nvim-lspconfig
- **Completion**: nvim-cmp
- **Fuzzy Finder**: Telescope
- **Syntax**: Treesitter
- **AI**: GitHub Copilot

### Profiles

Automatically detect project type and load relevant plugins:

- **JavaScript**: Triggered by `package.json`  
  Includes: toggleterm, nvim-dap, nvim-dap-ui

- **DevOps**: Triggered by `charts/` or `kustomization.yaml`  
  Includes: kube-utils, vim-helm, vim-terraform, ansible-vim, schemastore

### Key Features

- Auto-switching profiles when changing directories
- Which-key for visual keybinding menu
- Statusline shows active profile
- LSP auto-configuration via mason-tool-installer

See [nvim/README.md](nvim/README.md) for full documentation.

## Zsh

Basic zsh configuration (to be updated).

## Tmux

Tmux configuration (to be updated).

## Git

Git global configuration (to be updated).

## Kanata

Advanced keyboard remapper for improved ergonomics.

**Features:**
- Caps Lock → Escape (tap) / Control (hold)
- Navigation layer with vim-style keys (Caps + H/J/K/L)
- Function key mappings for macOS controls

**Prerequisites for macOS:**
- Karabiner VirtualHIDDevice driver v6.2.0 (REQUIRED)
- See [kanata/INSTALL-MACOS.md](kanata/INSTALL-MACOS.md) for full installation instructions

**Quick Start:**
```bash
# Start Kanata (requires sudo on macOS)
sudo kanata -c ~/.config/kanata/kanata.kbd
# (or fallback: sudo kanata -c ~/dotfiles/kanata/kanata.kbd)

# Or see full setup guide
cat ~/dotfiles/kanata/QUICKSTART.md
# (or: cat ~/.config/kanata/QUICKSTART.md)
```

See [kanata/README.md](kanata/README.md) for complete documentation.

## Manual Dependencies (if not using install.sh)

You can install everything in one go using the provided `Brewfile` (recommended):

```bash
# Install Homebrew first (if not installed)
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install everything from the repo Brewfile
brew bundle --file=Brewfile
```

Or use the installer which supports the Brewfile as well:

```bash
# Run the installer which will apply the repo Brewfile and bootstrap other pieces
chmod +x install.sh
./install.sh --brewfile

# To append missing requested packages into the repo Brewfile (creates backup):
./install.sh --update-brewfile

# Append and commit the changes automatically (requires git):
./install.sh --update-brewfile --commit-brewfile
```
If you prefer to install items individually, the minimal commands are below:

```bash
# Core
brew install neovim git

# Neovim essentials
brew install ripgrep fd tree-sitter node

# Optional fonts (recommended to install via `Brewfile` casks)
# Example:
brew install --cask font-victor-mono-nerd-font
brew install --cask font-caskaydia-cove-nerd-font
```

Notes:
- The Brewfile contains additional casks (fonts) and comments about npm global installs required for some language servers (e.g. `typescript-language-server`).
- The installer prefers using the repository `Brewfile`. If you request additional packages, you can use `--update-brewfile` to append them into the repo `Brewfile` (creates a backup). Add `--commit-brewfile` to automatically commit the change (requires `git`).
- After `brew bundle`, you may need to install some global npm packages; use `--npm-globals` with the installer to automate the most common ones.
- Zsh plugins (zsh-autocomplete, zsh-autosuggestions, zsh-syntax-highlighting) are installed via your preferred plugin manager or by cloning into your zsh config; the installer will print instructions when using `--brewfile`.

## Verification

After setup, verify everything works:

```bash
nvim
:checkhealth
:TSUpdate
```

## Troubleshooting

### Home Manager (local development)

The repository includes a small legacy wrapper at `~/.config/home-manager/home.nix` which imports `home/home.nix` for quick local testing if you still use Nix. This wrapper is provided for historical/compatibility reasons and is not actively maintained.

If you don't use Nix, ignore this wrapper and prefer the repo bootstrap and Homebrew workflows documented above.


If you plan to publish the flake or pin the repo tarball (legacy Nix workflow), the wrapper can be converted to a flake-friendly import; otherwise ignore this.


### Icons show as boxes
Install a Nerd Font and configure your terminal to use it.

### LSP not working
```vim
:Mason
:checkhealth
```

### Plugin errors
```vim
:Lazy sync
:Lazy clean
```

### Treesitter errors
```vim
:TSUpdate
:checkhealth nvim-treesitter
```

## License

Personal dotfiles - feel free to fork and customize!
