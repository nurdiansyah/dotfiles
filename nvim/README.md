# Neovim Configuration Notes

This is a personal reference document for my Neovim setup. Its purpose is to track the structure, installed plugins, and key configurations for my own use.

## 1. Configuration Structure

My setup is organized into logical directories to keep things clean and maintainable.

```
~/.config/nvim
├── lua/
│   ├── config/      -- Core Neovim settings (options, keymaps, etc.)
│   └── plugins/     -- Plugin specifications, one file per category.
└── init.lua         -- The main entry point.
```

## 2. Core Configuration (`lua/config/`)

These files control the fundamental behavior of Neovim.

* `options.lua`: Global settings like line numbers, indentation, and search behavior (`vim.opt`).
* `keymaps.lua`: Global key mappings that aren't specific to a plugin (`vim.keymap.set`). My `<leader>` key is `Space`.
* `autocmds.lua`: Automation rules, like formatting on save or highlighting yanked text.
* `lazy.lua`: The bootstrap and setup file for the `lazy.nvim` plugin manager.

## 3. Installed Plugins (`lua/plugins/`)

Plugins are managed by `lazy.nvim` and are defined in files within this directory.

### UI Enhancements

* **`nvim-lualine/lualine.nvim`**: A fast and highly configurable statusline.
* **`catppuccin/nvim`**: The colorscheme for the editor.
* **`nvim-tree/nvim-web-devicons`**: Adds file-type icons to various plugins like Lualine.

### Editing & Functionality

* **`nvim-telescope/telescope.nvim`**: A powerful fuzzy finder for files, text, buffers, and more.
* **`nvim-treesitter/nvim-treesitter`**: Provides advanced syntax highlighting and code parsing.
* **`numToStr/Comment.nvim`**: Easy commenting with `gcc` (line) and `gc` (block).

### LSP & Autocompletion

* **`williamboman/mason.nvim`**: Manages LSP servers, formatters, and linters.
* **`neovim/nvim-lspconfig`**: The base configuration for setting up LSP servers.
* **`hrsh7th/nvim-cmp`**: The autocompletion engine.

## 4. Key Mappings Log

I have not set any custom keybindings yet.

As I create mappings in `lua/config/keymaps.lua`, I will document the important ones here for my own reference.

## 5. External Dependencies

List of tools that need to be installed on the system for everything to work correctly.

* `Neovim` (recommended >= 0.8)
* A **Nerd Font** (for icons)
* `ripgrep` (`rg`) — used by Telescope's `live_grep`
* `fd` — fast file finder used by Telescope
* `tree-sitter-cli` — required by `nvim-treesitter` to build parsers
* `node` & `npm` — required by some plugins and language tooling
* `python3` & `pip` + `pynvim` (install with `pip3 install --user pynvim`) — for Python-based plugins
* `luarocks` or the bootstrapped `hererocks` environment (Lua 5.1) — some plugins expect `luarocks`
* `git` — plugin manager and plugin installation
* Xcode Command Line Tools (macOS) — needed to build native extensions
* Optional: `cargo` / Rust toolchain — used to build some native tools or parsers

Installation notes:

- Preferred: run the repository installer which will install Homebrew packages and bootstrap a `hererocks` Lua 5.1 environment:

```bash
chmod +x install.sh
./install.sh
```

- Manual (macOS/Homebrew) alternatives if you prefer manual installs:

```bash
brew install neovim node python git ripgrep fd tree-sitter luarocks
# optionally install rust (cargo) via rustup
```

After installing, verify and update tooling from Neovim:

```vim
:checkhealth
:checkhealth nvim-treesitter
:TSUpdate
```

## 6. Quick Setup Notes

This repo provides a convenience installer `install.sh` that installs required external tools (Homebrew packages and a local `hererocks` Lua 5.1 environment) used by this configuration. Run:

```bash
chmod +x install.sh
./install.sh
```

If you prefer to install tools manually (macOS/Homebrew), you can still run:

```bash
brew install tree-sitter
brew install luarocks
```

After installing, verify and update treesitter from Neovim:

```vim
:checkhealth nvim-treesitter
:TSUpdate
```

### Run the project installer

This repo includes a convenience installer `install.sh` that installs Homebrew packages (`tree-sitter`, `luarocks`) and bootstraps a `hererocks` Lua 5.1 environment used by `lazy.nvim`.

```bash
chmod +x install.sh
./install.sh
```


## 7. Copilot

I use a Copilot plugin in this config. To install and enable plugins, run:

```vim
:Lazy sync
```

By default the Copilot entry uses `zbirenbaum/copilot.lua` with suggestion auto-trigger and `<C-l>` to accept suggestions. If you prefer the official plugin, replace it with `github/copilot.vim` in `lua/plugins/init.lua`.

## 8. Lua / Luarocks / Hererocks

Some plugins require a Lua 5.1 environment or `luarocks` available in the path. This config bootstraps a local `hererocks` environment at `~/.local/share/nvim/lazy-rocks/hererocks` (Lua 5.1 + `luarocks`) via the repository `install.sh`.

If you see warnings like "lua version 5.1 needed" or "{luarocks} not installed", run the installer and ensure the `hererocks` bin directory is on your `PATH`:

```bash
./install.sh
# then, if needed, add to your shell rc (example for zsh):
echo 'export PATH="$HOME/.local/share/nvim/lazy-rocks/hererocks/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

After that, re-open Neovim and run:

```vim
:checkhealth
:TSUpdate
```
