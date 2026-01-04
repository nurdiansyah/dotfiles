# Neovim Configuration

A modular, profile-based Neovim configuration with support for JavaScript/TypeScript and DevOps workflows.

## Features

- **Profile-based plugin loading**: Auto-detect project type and load relevant plugins
- **Lazy loading**: Fast startup with lazy.nvim
- **LSP ready**: Pre-configured language servers via Mason
- **GitHub Copilot**: AI-powered code completion
- **Modern UI**: Lualine statusline, Telescope fuzzy finder, Treesitter syntax
- **Which-key integration**: Visual keybinding menu

## Structure

```
~/.config/nvim
├── init.lua
├── lua/
│   ├── core/           -- Core configuration
│   │   ├── lazy.lua    -- Plugin manager bootstrap
│   │   ├── options.lua -- Vim options
│   │   ├── keymaps.lua -- Key mappings (which-key integrated)
│   │   ├── autocmds.lua -- Auto commands & profile switching
│   │   └── statusline.lua -- Lualine with profile indicator
│   ├── plugins/
│   │   ├── init.lua    -- Base plugins (loaded for all profiles)
│   │   └── profiles/   -- Profile-specific plugins
│   │       ├── javascript.lua -- JS/TS tools (toggleterm, dap)
│   │       └── devops.lua     -- K8s/Terraform/Ansible tools
│   ├── config/
│   │   └── lsp/        -- LSP configurations
│   └── utils/
│       ├── root.lua    -- Project type detection
│       └── state.lua   -- Profile state management
```

## Installation

### Prerequisites

```bash
# Install Neovim (>= 0.9)
brew install neovim

# Install dependencies
brew install git ripgrep fd tree-sitter node

# Optional: Install a Nerd Font for icons
brew install --cask font-jetbrains-mono-nerd-font
```

### Quick Setup

```bash
# Clone to your config directory
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
ln -s ~/dotfiles/nvim ~/.config/nvim

# First launch will auto-install plugins
nvim
```

## Profiles

Profiles are automatically detected based on project files:

### JavaScript Profile
**Triggers**: `package.json` detected  
**Plugins**: toggleterm, nvim-dap, dap-ui  
**LSP**: typescript-language-server, eslint

### DevOps Profile
**Triggers**: `charts/` dir or `kustomization.yaml` detected  
**Plugins**: kube-utils, vim-helm, vim-terraform, ansible-vim, schemastore  
**LSP**: yaml-language-server, terraform-ls, ansible-language-server

### Manual Override

Set profile via environment variable:
```bash
NVIM_PROFILE=devops nvim
```

Or in `.nvim.lua` (project root):
```lua
vim.g.nvim_profile = "javascript"
```

## Base Plugins

Core plugins loaded for all profiles:

- **UI**: tokyonight colorscheme, lualine, nvim-tree, which-key
- **Editor**: telescope, treesitter, Comment.nvim, nvim-autopairs
- **LSP**: nvim-lspconfig, mason, mason-lspconfig, mason-tool-installer
- **Completion**: nvim-cmp + sources
- **Git**: gitsigns
- **AI**: copilot.lua (GitHub Copilot)
- **Language-specific**: typescript.nvim, nvim-jdtls

## Key Mappings

Leader key: `<Space>`

Press `<Space>` to see all available keybindings via which-key.

### Quick Reference

**Navigation**:
- `<C-h/j/k/l>` - Window navigation
- `<S-h/l>` - Buffer navigation
- `<leader>e` - Toggle file explorer

**Find** (`<leader>f`):
- `<leader>ff` - Find files
- `<leader>fg` - Live grep
- `<leader>fb` - Find buffers
- `<leader>fh` - Help tags

**Buffer** (`<leader>b`):
- `<leader>bd` - Delete buffer

**File**:
- `<leader>w` - Save
- `<leader>q` - Quit

**Window Resize**:
- `<C-Up/Down/Left/Right>` - Resize splits

## LSP Tools

Auto-installed via mason-tool-installer:

- jdtls (Java)
- terraform-ls
- ansible-language-server
- yaml-language-server
- typescript-language-server
- prettier
- eslint-lsp

## Copilot

GitHub Copilot is enabled by default:
- `<C-l>` - Accept suggestion
- `:Copilot panel` - Open panel

To authenticate:
```vim
:Copilot auth
```

## Customization

### Add Your Own Keymaps

Edit `lua/core/keymaps.lua` and add to the `wk.add()` block:

```lua
wk.add({
  { "<leader>x", ":YourCommand<CR>", desc = "Your description", mode = "n" },
})
```

### Create a New Profile

1. Create `lua/plugins/profiles/myprofile.lua`:
```lua
return {
  { "author/plugin-name" },
}
```

2. Update `lua/utils/root.lua` to detect your project type:
```lua
if vim.fn.filereadable("myfile.txt") == 1 then
  return "myprofile"
end
```

3. Update statusline icons in `lua/core/statusline.lua`:
```lua
local ui = {
  myprofile = { icon = "MY", color = "#FF0000" },
  -- ...
}
```

## Troubleshooting

### Icons not showing
Install a Nerd Font and configure your terminal to use it.

### Treesitter errors
```vim
:TSUpdate
:checkhealth nvim-treesitter
```

### LSP not working
```vim
:checkhealth
:Mason
```

### Plugin errors
```vim
:Lazy sync
:Lazy clean
```

## Profile Switching

Profile switches automatically when you `:cd` to a different project. The statusline shows the current active profile (JS/K8S/*).

Manual reload:
```vim
:Lazy reload
```

