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
# ln -s ~/dotfiles/zsh ~/.config/zsh

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
sudo kanata -c ~/.dotfiles/kanata/kanata.kbd

# Or see full setup guide
cat ~/.dotfiles/kanata/QUICKSTART.md
```

See [kanata/README.md](kanata/README.md) for complete documentation.

## Manual Dependencies (if not using install.sh)

```bash
# Core
brew install neovim git

# Neovim essentials
brew install ripgrep fd tree-sitter node

# Optional font
brew install --cask font-jetbrains-mono-nerd-font
```

## Verification

After setup, verify everything works:

```bash
nvim
:checkhealth
:TSUpdate
```

## Troubleshooting

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
