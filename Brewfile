# Brewfile — package manifest. Verify entries and run `brew bundle --file=Brewfile` to install.
# - Each entry includes a short comment describing its purpose or how it maps from other package sources.
# - Items marked with # TODO / verify need manual verification before merging.
# - Use: brew bundle --file=Brewfile

tap "nikitabobko/tap" # for aerospace app
tap "FelixKratz/formulae" # for sketchybar

# Core tools
brew "coreutils"           # GNU core utilities used by scripts and tools
brew "curl"                # HTTP client (used by installers / scripts)
brew "wget"                # Alternative HTTP downloader
brew "git"                 # Version control
brew "gnupg"               # GPG for signing and encryption
brew "gh"                  # GitHub CLI (used in workflows)
brew "git-lfs"             # Git LFS for large files
brew "git-delta"           # Enhanced git diff viewer

# Editor & dev tools
brew "neovim"              # Neovim editor (used by nvim config)
brew "lazygit"             # TUI for git
brew "stylua"              # Lua formatter for Neovim config
brew "rust-analyzer"       # LSP for Rust development

# Languages & build tools
brew "python@3.11"         # Python 3.11 (replaces nix python311)
brew "pipx"                # Python package manager for global tools
brew "gcc"                 # GNU compiler toolchain
brew "cmake"               # Build system
brew "pkg-config"          # pkg-config for native builds
brew "shfmt"               # Shell formatter

# Utilities
brew "fd"                  # fast alternative to find
brew "ripgrep"             # fast grep
brew "jq"                  # JSON processor
brew "yq"                  # YAML processor
brew "fzf"                 # Fuzzy finder
brew "timewarrior"         # Time tracking CLI

# Kubernetes & infra
brew "k9s"                 # Kubernetes CLI UI (maps from k9s)
brew "kubectl"             # Kubernetes control tool
brew "helm"                # Kubernetes package manager (helm)

# Misc
brew "btop"                # system monitor (btop)
brew "bat"                 # cat with syntax highlighting
brew "direnv"              # directory-based env switcher
brew "eza"                 # modern `ls` replacement
brew "fastfetch"           # system info fetcher
brew "mcfly"               # shell history tool
brew "nushell"             # shell (maps from nushell)
brew "starship"            # cross-shell prompt (maps from starship)
brew "watchman"            # file watching tool
brew "wireguard-tools"     # WireGuard utilities
brew "zoxide"              # smarter `cd` (zoxide)

# Tools that likely require verification / custom taps / manual installs
brew "lazysql"          # verify formula or upstream packaging
brew "kanata"         # install manual via GitHub releases becouse no cmd_allowed in brew formula
brew "sketchybar"       # likely manual / cask / custom tap required
brew "tree-sitter"      # verify: may be `tree-sitter-cli` formula
# The following may require custom taps or manual installs (verify per-OS):
# brew "lua-language-server" # verify: often provided by custom taps or Luarocks

# Fonts (casks)
cask "font-jetbrains-mono-nerd-font"  # nerd font used in UI/terminal
cask "sf-symbols"              # macOS SF Symbols font
cask "font-hack-nerd-font"         # nerd font used in terminal + editor
cask "font-meslo-lg-nerd-font"     # nerd font used in terminal + editor
# cask "font-victor-mono-nerd-font"   # nerd font used for terminal + editor
# cask "font-caskaydia-cove-nerd-font" # nerd font used in UI/terminal

cask "flashspace"      # verify: may require manual install or custom taps
# cask "FelixKratz/formulae/sketchybar"  # sketchybar from FelixKratz tap
# cask "aerospace"        # Aerospace app for window management (from nikitabobko/aerospace tap)
# npm / global packages (install via npm/yarn)
# - bash-language-server: npm i -g bash-language-server  # used as LSP for bash (verify preferred node manager)
# - typescript-language-server: npm i -g typescript-language-server typescript  # JS/TS LSP
# - Additional language servers (e.g., lua-language-server, python-language-server) may require alternate installers — check upstream docs
# Use your preferred node manager (npm, pnpm, corepack) to install global LSP packages; consider local project installs for reproducibility.

# zsh plugins (install via plugin manager or clone to ~/.zsh)
# - zsh-autocomplete          # Autocomplete for zsh
# - zsh-autosuggestions      # Suggests commands as you type
# - zsh-syntax-highlighting # Syntax highlighting for zsh

# NOTES
