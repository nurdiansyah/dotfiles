# Nix Darwin + Home Manager Configuration

Modern declarative configuration management for macOS using Nix Darwin and Home Manager.

## 🎯 Filosofi

Instead of scattered shell scripts and manual setup, everything di-declare dalam Nix:
- **Reproducible** - Exact environment setiap saat
- **Declarative** - Specify apa yang diinginkan, bukan step-by-step
- **Rollback** - Revert ke previous generation dengan mudah
- **Pure** - No side effects, everything tracked in flake.lock

## 📁 Struktur

```
dotfiles/
├── flake.nix                   # Main Nix flake entry point
├── flake.lock                  # Locked dependency versions
├── install-nix.sh              # Installation script
├── darwin/
│   └── configuration.nix       # macOS system config
├── home/
│   ├── home.nix               # Home Manager config
│   └── zsh/
│       └── init.zsh           # Zsh initialization
├── nvim/                       # Neovim config
├── tmux/                       # Tmux config
├── git/                        # Git config
└── README.md
```

## 🚀 Installation

### 1. **Install Nix** (if not already installed)
```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### 2. **Clone Dotfiles**
```bash
git clone https://github.com/nurdiansyah/dotfiles ~/.dotfiles
cd ~/.dotfiles
```

### 3. **Run Installation Script**
```bash
bash install-nix.sh
```

Atau manual:
```bash
# Enable flakes first
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# Apply configuration
darwin-rebuild switch --flake ~/.dotfiles#default
```

### 4. **Reload Shell**
```bash
exec zsh
```

## 📚 Configuration Files

### `flake.nix`
Main entry point yang mendefinisikan:
- Input dependencies (nixpkgs, darwin, home-manager)
- Output configurations
- System packages

### `darwin/configuration.nix`
macOS system-level configuration:
- System packages
- Homebrew packages & casks
- Keyboard shortcuts
- Finder settings
- Dock configuration
- Nix settings

### `home/home.nix`
User-level configuration (via Home Manager):
- Shell setup (zsh)
- Editor (neovim)
- Git configuration
- Tmux configuration
- Environment variables
- User packages

### `home/zsh/init.zsh`
Zsh shell initialization:
- Aliases
- Functions
- Profile switching untuk Nvim
- Git shortcuts
- Kubernetes aliases

## 📦 Installed packages
Berikut ringkasan paket yang dideklarasikan di konfigurasi (dibagi per kategori). Ini diambil dari `darwin/configuration.nix`, `home/home.nix` dan `homebrew` lists — cocok untuk referensi cepat saat mengaudit apa yang akan di-install.

### System (darwin/configuration.nix)
- coreutils
- curl
- wget
- git
- gnupg
- openssh
- neovim
- zsh
- gcc
- cmake
- pkg-config
- fd
- ripgrep
- tree-sitter
- jq
- yq
- fzf
- n (node version manager)
- python311
- python311Packages.pip
- kubectl
- kubernetes-helm
- btop
- bat
- exa
- delta

### User (home/home.nix)
- nodejs (user-scoped)
- pnpm (user-scoped)

### Homebrew (darwin.configuration - `homebrew.brews` / `homebrew.casks`)
- Brews:
  - font-jetbrains-mono
  - font-hack-nerd-font
  - mcfly
  - direnv
  - watchman
- Casks:
  - kitty

> Tip: gunakan `darwin-rebuild check --flake .#<machine>` untuk melihat apakah paket-paket di atas ada yang bentrok atau memerlukan build khusus untuk arsitektur target (x86_64-darwin / aarch64-darwin).


## 🔄 Usage

### Apply Configuration Changes
```bash
cd ~/.dotfiles

# See what will change
darwin-rebuild check --flake .#default

# Apply changes
darwin-rebuild switch --flake .#default
```

### Update Dependencies
```bash
cd ~/.dotfiles
nix flake update
darwin-rebuild switch --flake .#default
```

### Rollback to Previous Generation
```bash
# List previous generations
darwin-rebuild list-generations

# Switch to specific generation
darwin-rebuild switch --flake . --profile /nix/var/nix/profiles/system-2-link
```

### View System Information
```bash
# Show current generation
darwin-rebuild info

# Show Nix store stats
nix store stats

# Show what's installed
nix-store -q --requisites /run/current-system
```

## 🎨 Customization

### Add System Package
Edit `darwin/configuration.nix`:
```nix
environment.systemPackages = with pkgs; [
  # ... existing packages ...
  newPackage
];
```

### Add User Package
Edit `home/home.nix`:
```nix
home.packages = with pkgs; [
  # ... existing packages ...
  newPackage
];
```

### Add Homebrew Package
Edit `darwin/configuration.nix`:
```nix
homebrew.brews = [
  # ... existing packages ...
  "package-name"
];
```

### Add Alias
Edit `home/zsh/init.zsh`:
```bash
alias newcmd='command --with-args'
```

### Add Function
Edit `home/zsh/init.zsh`:
```bash
my_function() {
  echo "Do something"
}
```

## 🔧 Common Tasks

### Change Shell Theme
Edit `home/home.nix`, change `programs.zsh.oh-my-zsh.theme`:
```nix
programs.zsh.oh-my-zsh.theme = "powerlevel10k";
```

### Switch to Starship Prompt
Comment out Powerlevel10k in `home/home.nix` dan uncomment Starship:
```nix
programs.starship = {
  enable = true;
  enableZshIntegration = true;
};
```

### Add New Git Alias
Edit `home/home.nix`:
```nix
programs.git.aliases = {
  # ... existing aliases ...
  myalias = "my-git-command";
};
```

### Modify System Defaults
Edit `darwin/configuration.nix`:
```nix
system.defaults.NSGlobalDomain = {
  # macOS user defaults
};
```

## 📊 Switching Nvim Profile

Profile switching masih work dengan Nix setup:
```bash
nvim_profile javascript    # Set JavaScript profile
nvim_profile java          # Set Java profile
nvim_profile devops        # Set DevOps profile
nvim_profile_show          # Show current profile
```

Profile disimpan di `~/.config/nvim/state/profile`.

## 🐛 Troubleshooting

### Nix command not found
```bash
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

### Darwin-rebuild not found
```bash
nix run nixpkgs#darwin -- switch-generation 1
```

### Flakes not enabled
Ensure `~/.config/nix/nix.conf` has:
```
experimental-features = nix-command flakes
```

### Home Manager issues
```bash
# Reset home-manager
home-manager switch --flake . --force

# Or rebuild from scratch
rm ~/.config/home-manager
home-manager switch --flake . --force
```

## 📖 Resources

- [Nix Darwin Docs](https://github.com/lnl7/nix-darwin)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nixpkgs Search](https://search.nixos.org/packages)
- [NixOS Wiki](https://wiki.nixos.org/)
- [Nix Language Docs](https://nix.dev/)

## 💾 Backups

Previous configurations are automatically preserved through Nix generations:
```bash
# List all generations
darwin-rebuild list-generations

# Rollback to previous
darwin-rebuild switch --profile /nix/var/nix/profiles/system-<N>-link
```

## ✨ Features

✅ **Declarative Configuration** - All config in Nix
✅ **Reproducible Builds** - Same environment everywhere
✅ **Easy Rollback** - Revert to previous state instantly
✅ **Multiple Profiles** - Different machines with one flake
✅ **Version Pinning** - Locked dependencies in flake.lock
✅ **Home Manager** - User-level config management
✅ **Homebrew Integration** - Manage macOS apps via Nix
✅ **Neovim Integration** - Config synced with dotfiles
✅ **Git Integration** - User config in dotfiles

## 🤝 Contributing

To customize for your setup:
1. Fork or edit locally
2. Modify `flake.nix`, `darwin/`, `home/` as needed
3. Test: `darwin-rebuild check --flake .#default`
4. Apply: `darwin-rebuild switch --flake .#default`
5. Commit changes to git

## 📝 Notes

- Nix learns your dependencies and can reproduce your exact environment
- Use `nix develop` to create temporary development environments
- Use `nix shell` to run packages without installing them
- All changes are version-controlled and easy to diff
