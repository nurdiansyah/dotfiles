# macOS Architecture Guide

Understanding Intel vs Apple Silicon in Nix Darwin.

## 🏗️ Architecture Types

### Intel (x86_64-darwin)
- **Identifier:** x86_64-darwin
- **Machines:** MacBook Air/Pro (pre-2020)
- **Bits:** 64-bit
- **Nix System:** x86_64-darwin
- **Example:** MacBook with Intel Core i7

### Apple Silicon (aarch64-darwin)
- **Identifier:** aarch64-darwin
- **Machines:** MacBook Air/Pro (M1+), Mac Mini (M1+), Mac Studio (M1+)
- **Bits:** 64-bit ARM
- **Nix System:** aarch64-darwin
- **Generations:**
  - M1, M1 Pro, M1 Max (2021)
  - M2, M2 Pro, M2 Max (2022)
  - M3, M3 Pro, M3 Max (2023)
  - M4, M4 Pro, M4 Max (2024)

## 🔍 Detecting Your Architecture

### Method 1: Terminal Command
```bash
uname -m
# Intel:        x86_64
# Apple Silicon: arm64
```

### Method 2: System Information
```bash
system_profiler SPHardwareDataType | grep Processor
# Intel:        Processor Name: Intel Core i7
# Apple Silicon: Processor Name: Apple M4 (for example)
```

### Method 3: Check Current Config
```bash
# Show what architecture is running now
nix eval --impure --expr "builtins.currentSystem"

# Show architecture of your Nix
file /nix/nix
```

## 💾 Nix Darwin Architecture Mapping

| Architecture | Nix System | uname -m | File Type |
|--------------|-----------|----------|-----------|
| **Intel** | x86_64-darwin | x86_64 | Mach-O 64-bit |
| **Apple Silicon** | aarch64-darwin | arm64 | Mach-O 64-bit ARM64 |

## 📦 Package Support

### Intel (x86_64-darwin)
- **Status:** Fully supported
- **Nixpkgs:** All packages available
- **Performance:** Native execution
- **Notes:** Older architecture, excellent compatibility

### Apple Silicon (aarch64-darwin)
- **Status:** Fully supported (native)
- **Nixpkgs:** Most packages available (aarch64 native)
- **Rosetta:** x86_64 fallback via emulation
- **Performance:** Fast native execution
- **Notes:** Newer, some packages still being added

## 🔄 Cross-Compilation

### Build for Different Architecture

```bash
# On Intel Mac, build for Apple Silicon
nix build --system aarch64-darwin /path/to/config

# On Apple Silicon, build for Intel
nix build --system x86_64-darwin /path/to/config
```

### Rosetta Support (Apple Silicon)

Mac Mini with M4 dapat menjalankan Intel binaries via Rosetta:

```nix
# In machines.nix for Apple Silicon
nix.settings.extra-platforms = [
  "aarch64-darwin"
  "x86_64-darwin"  # Enable Rosetta fallback
];
```

## 🚀 Installation Considerations

### For Intel MacBook
```bash
# Use x86_64-darwin system
darwin-rebuild switch --flake ~/.dotfiles#macbook
```

### For Apple Silicon Mac Mini
```bash
# Use aarch64-darwin system (M4)
darwin-rebuild switch --flake ~/.dotfiles#macmini
```

## ⚙️ Nix Configuration per Architecture

### Shared Config (flake.nix)
```nix
machines = {
  macbook = {
    system = "x86_64-darwin";
  };
  macmini = {
    system = "aarch64-darwin";
  };
};
```

### Machine-Specific Packages

```nix
# In machines.nix
macbook = {
  # Intel-specific packages
  environment.systemPackages = with pkgs; [
    # Package yang lebih cepat di Intel
  ];
};

macmini = {
  # Apple Silicon specific
  environment.systemPackages = with pkgs; [
    # ARM64-native packages
  ];
};
```

## 🔧 Troubleshooting Architecture Issues

### "Unsupported architecture" Error
```bash
# Check what system flake is trying to use
nix eval ~/.dotfiles#darwinConfigurations.macmini.system

# Should be: "aarch64-darwin" for M4 Mac
```

### Binary Cache Misses on Apple Silicon
Some packages might not have aarch64-darwin binaries:
```bash
# Build locally
darwin-rebuild switch --flake ~/.dotfiles#macmini --keep-going

# Or fallback to Rosetta (slower)
nix.settings.extra-platforms = [ "x86_64-darwin" ];
```

### Mixed Architecture Development

If developing on Intel but need to target Apple Silicon:
```bash
# Cross-compile for testing
nix develop --system aarch64-darwin
```

## 📊 Performance Comparison

| Operation | Intel MacBook | Apple Silicon M4 |
|-----------|---------------|------------------|
| **Nix eval** | ~2-3s | ~1-2s (faster) |
| **Build simple package** | ~5-10s | ~3-5s (faster) |
| **Rosetta emulation** | N/A | ~50% overhead |
| **Native execution** | Fast | Very fast |

## 🎯 Best Practices

1. **Use native system** - Always match machine architecture
   ```bash
   darwin-rebuild switch --flake ~/.dotfiles#macmini  # Not #macbook
   ```

2. **Cache strategy** - Leverage official binary cache
   ```nix
   nix.settings.substituters = [
     "https://cache.nixos.org"  # Official cache
   ];
   ```

3. **Conditional packages** - Use machine-specific optimization
   ```nix
   home.packages = with pkgs; [
   ] ++ lib.optionals (machineType == "macmini") [
     # M4-optimized packages
   ];
   ```

4. **Keep flake.lock** - Pin versions for consistency
   ```bash
   git add flake.lock
   git commit -m "pin nixpkgs versions"
   ```

## 📚 Resources

- [NixOS Wiki - Darwin](https://nixos.wiki/wiki/Nix_on_Apple_Silicon)
- [Nix Darwin Issues](https://github.com/lnl7/nix-darwin/issues)
- [Nixpkgs Architecture Support](https://nixos.org/manual/nixpkgs/stable/#chap-meta)
- [Apple Silicon Support](https://github.com/NixOS/nixpkgs/labels/aarch64-darwin)
