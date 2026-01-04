# Multi-Machine Nix Darwin Configuration

Support untuk multiple macOS machines dengan berbeda architecture:
- **MacBook** = Intel (x86_64)
- **Mac Mini** = Apple Silicon M4 (aarch64)

## 🖥️ Supported Machines

| Machine | CPU | Architecture | System | Hostname |
|---------|-----|--------------|--------|----------|
| **MacBook** | Intel | x86_64-darwin | `x86_64-darwin` | nurdiansyah-macbook |
| **Mac Mini** | Apple Silicon M4 | aarch64-darwin | `aarch64-darwin` | nurdiansyah-macmini |

## 📁 Configuration Structure

```
dotfiles/
├── flake.nix                      # Main entry with multi-machine support
├── darwin/
│   ├── configuration.nix          # Shared system config
│   └── machines.nix               # Machine-specific overrides
└── home/
    ├── home.nix                   # Shared home config
    └── zsh/
        └── init.zsh               # Shell initialization
```

## 🚀 Installation

### First Time Setup

```bash
cd ~/.dotfiles

# Automatic detection
bash install-nix.sh

# Or manual selection
MACHINE_TYPE=macbook bash install-nix.sh
MACHINE_TYPE=macmini bash install-nix.sh
```

Script akan:
1. ✅ Detect machine type (atau tanya user)
2. ✅ Enable Nix flakes
3. ✅ Apply configuration untuk machine tersebut
4. ✅ Show next steps

### Manual Setup

```bash
# For MacBook
darwin-rebuild switch --flake ~/.dotfiles#macbook

# For Mac Mini
darwin-rebuild switch --flake ~/.dotfiles#macmini
```

## 🔄 Switching Between Machines

Jika sudah punya Nix & flakes, bisa switch configuration:

```bash
# Dari MacBook ke Mac Mini
darwin-rebuild switch --flake ~/.dotfiles#macmini

# Dari Mac Mini ke MacBook
darwin-rebuild switch --flake ~/.dotfiles#macbook
```

Hostname akan automatically update sesuai konfigurasi.

## 🔧 Customization per Machine

### Add Machine-Specific Packages

Edit `darwin/machines.nix`:

```nix
# MacBook-specific
macbook = {
  environment.systemPackages = with pkgs; [
    # Laptop tools
    tlp  # Power management
  ];
};

# Mac Mini-specific
macmini = {
  environment.systemPackages = with pkgs; [
    # Desktop tools
  ];
};
```

### Add Machine-Specific Home Config

Edit `home/home.nix` dan gunakan `machineType`:

```nix
home.packages = with pkgs; [
  # Common packages
] ++ lib.optionals (machineType == "macbook") [
  # MacBook-only packages
] ++ lib.optionals (machineType == "macmini") [
  # Mac Mini-only packages
];
```

## 📊 Machine Details

### MacBook Configuration (Intel)
- **Hostname:** nurdiansyah-macbook
- **Architecture:** x86_64-darwin (Intel)
- **Type Key:** macbook
- **CPU:** Intel (x86_64)
- **Use Case:** Laptop development
- **Special Config:**
  - Trackpad enabled
  - Power management (tlp, powertop)
  - 4 max Nix jobs (conservative for laptop)
  - SSD-optimized

### Mac Mini Configuration (Apple Silicon M4)
- **Hostname:** nurdiansyah-macmini
- **Architecture:** aarch64-darwin (ARM64)
- **Type Key:** macmini
- **CPU:** Apple Silicon M4 (aarch64)
- **Use Case:** Desktop development
- **Special Config:**
  - 8 max Nix jobs (aggressive for desktop)
  - Rosetta x86_64 fallback support
  - ARM64-native packages prioritized
  - More aggressive caching

## 📝 Adding New Machine

### Step 1: Update flake.nix

Edit machines dict di `outputs`:

```nix
machines = {
  macbook = {
    hostname = "nurdiansyah-macbook";
    computerName = "Nurdiansyah's MacBook";
    localHostName = "nurdiansyah-mbp";
    system = "x86_64-darwin";  # Intel
  };
  macmini = {
    hostname = "nurdiansyah-macmini";
    computerName = "Nurdiansyah's MacMini";
    localHostName = "nurdiansyah-mini";
    system = "aarch64-darwin";  # Apple Silicon M4
  };
  
  # Add new machine
  macstudio = {
    hostname = "nurdiansyah-macstudio";
    computerName = "Nurdiansyah's Mac Studio";
    localHostName = "nurdiansyah-studio";
    system = "aarch64-darwin";  # M2 Max is ARM64
  };
};
```

### Step 2: Update machines.nix

Add architecture-specific configuration:

```nix
configs = {
  macbook = {
    # Intel-specific setup
  };
  macmini = {
    # Apple Silicon M4 setup
  };
  
  # Add new machine
  macstudio = {
    environment.systemPackages = with pkgs; [
      # M2 Max optimized packages
    ];
    
    nix.settings.max-jobs = 10;  # M2 Max has more cores
  };
};
```

### Step 3: Apply

```bash
darwin-rebuild switch --flake ~/.dotfiles#macstudio
```

## 🎯 Checking Current Machine

```bash
# Show current hostname
hostname

# Show current flake generation
darwin-rebuild list-generations | head -1

# Show which machine type is active
cat ~/.config/nvim/state/profile 2>/dev/null || echo "default"
```

## 📋 Common Commands

```bash
# Apply to current machine
darwin-rebuild switch --flake ~/.dotfiles

# Apply specific machine
darwin-rebuild switch --flake ~/.dotfiles#macbook
darwin-rebuild switch --flake ~/.dotfiles#macmini

# Check what would change
darwin-rebuild check --flake ~/.dotfiles#macbook

# Show available machines
nix flake show ~/.dotfiles

# Update all dependencies
nix flake update
darwin-rebuild switch --flake ~/.dotfiles#macbook

# Rollback to previous generation
darwin-rebuild switch --profile /nix/var/nix/profiles/system-N-link
```

## 🔍 Debugging

### Show current configuration
```bash
# What flake config is active
nix flake show ~/.dotfiles

# Show current system generation
darwin-rebuild list-generations

# Show machine-specific config
cat ~/.config/nix/nix.conf
```

### Test configuration
```bash
# Dry-run untuk check errors
darwin-rebuild check --flake ~/.dotfiles#macbook

# Verbose output
darwin-rebuild switch --flake ~/.dotfiles#macbook --show-trace

# Show what changed
darwin-rebuild switch --flake ~/.dotfiles#macbook --verbose
```

## 🚨 Troubleshooting

### "Unknown flake" error
```bash
# Ensure flake.nix exists and valid
cd ~/.dotfiles
cat flake.nix | head -5

# List available machines
nix flake show
```

### Machine not switching
```bash
# Check if darwin-rebuild can see the config
nix eval ~/.dotfiles#darwinConfigurations.macbook.system

# Force rebuild
darwin-rebuild switch --flake ~/.dotfiles#macbook --force-rebuild
```

### Hostname not updating
```bash
# Verify hostname was changed
hostname

# Check system preferences
scutil --get ComputerName
scutil --get HostName
scutil --get LocalHostName
```

## 📚 Examples

### Only install on MacBook
```nix
# In home.nix
home.packages = with pkgs; [
] ++ lib.optionals (machineType == "macbook") [
  some-laptop-tool
];
```

### Different node version per machine
```nix
# In home/home.nix
programs.nodejs.version = 
  if machineType == "macbook" then "18" else "20";
```

### Machine-specific aliases
```bash
# In home/zsh/init.zsh
if [[ $(hostname) == *"macbook"* ]]; then
  alias battery='pmset -g battery'
fi
```

## 🔐 Security Notes

- Flake.lock pinned untuk reproducibility
- Machine-specific configs tidak menyimpan secrets
- Use `~/.zsh_local` untuk machine-specific tokens
- Git track flake.lock untuk sync antar machines

## 💡 Pro Tips

1. **Sync dengan Git** - Commit flake.lock setelah update
   ```bash
   nix flake update
   git add flake.lock
   git commit -m "chore: update flake inputs"
   ```

2. **Use same config** - Bedakan hanya dengan packages/settings
   ```bash
   # Share sebagian besar, override hanya yang perlu
   ```

3. **Test perubahan** - Selalu check sebelum switch
   ```bash
   darwin-rebuild check --flake ~/.dotfiles#macmini
   ```

4. **Keep generations** - Nix auto-keeps previous
   ```bash
   # Bisa rollback kapan saja
   darwin-rebuild switch --profile /nix/var/nix/profiles/system-N-link
   ```
