# Dotfiles

Personal configuration files for macOS development environment.

## Structure

```
dotfiles/
├── nvim/           -- Neovim config (profile-based plugins)
├── zsh/            -- Zsh shell config
├── tmux/           -- Tmux configuration
├── git/            -- Git config
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

```bash
chmod +x install.sh
./install.sh
```

This will install:
- Homebrew packages (neovim, git, ripgrep, fd, tree-sitter, node)
- Nerd Font (JetBrains Mono Nerd Font)
- Lua 5.1 via hererocks (for Neovim plugins)

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
# Run the installer which can apply the Brewfile and bootstrap other pieces
chmod +x install.sh
./install.sh --brewfile
```

If you prefer to install items individually, the minimal commands are below:

```bash
# Core
brew install neovim git

# Neovim essentials
brew install ripgrep fd tree-sitter node

# Optional font
brew install --cask font-jetbrains-mono-nerd-font
```

Notes:
- The Brewfile contains additional casks (fonts) and comments about npm global installs required for some language servers (e.g. `typescript-language-server`).
- After `brew bundle`, you may need to install some global npm packages.
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

The repository includes a small wrapper at `~/.config/home-manager/home.nix` which imports `home/home.nix` for quick local testing. This wrapper imports files from the working tree and therefore requires impure evaluation when running Home Manager locally.

Use this command to apply the user config locally (development):

```bash
nix run github:nix-community/home-manager#home-manager -- switch --impure
```

For CI or reproducible evaluation, prefer running Home Manager via flakes (no `--impure`):

```bash
home-manager switch --flake .
# or for system+home on macOS:
# sudo darwin-rebuild switch --flake .#<machine>
```

If you plan to publish the flake or pin the repo tarball, the wrapper can be converted to a flake-friendly import and `--impure` will no longer be necessary.


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
