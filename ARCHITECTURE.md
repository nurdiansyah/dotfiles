# macOS Architecture Guide

Understanding Intel vs Apple Silicon.

## 🏗️ Architecture Types

### Intel (x86_64-darwin)
- **Identifier:** x86_64-darwin
- **Machines:** MacBook Air/Pro (pre-2020)
- **Bits:** 64-bit
- **System identifier:** x86_64
- **Example:** MacBook with Intel Core i7

### Apple Silicon (aarch64-darwin)
- **Identifier:** aarch64-darwin
- **Machines:** MacBook Air/Pro (M1+), Mac Mini (M1+), Mac Studio (M1+)
- **Bits:** 64-bit ARM
- **System identifier:** aarch64
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

### Method 3: Check Binary Architecture
```bash
# Inspect the kanata binary or other tooling
file $(which kanata)
# Example output: Mach-O 64-bit executable (x86_64) or Mach-O 64-bit arm64
```

## 💾 Architecture Mapping

| Architecture | uname -m | File Type |
|--------------|----------|-----------|
| **Intel** | x86_64 | Mach-O 64-bit |
| **Apple Silicon** | arm64 | Mach-O 64-bit ARM64 |

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

## 🔄 Compatibility & Rosetta

If running on Apple Silicon, some Intel-only binaries will run under Rosetta 2. To check if an app will run natively or under Rosetta, inspect the binary:

```bash
file /usr/local/bin/somebinary
```

If you need to run Intel-only tooling on Apple Silicon, enable Rosetta for the specific app or install an Intel build via Homebrew (x86_64) and use Rosetta where necessary.

For cross-compilation and multi-arch builds, use the toolchain for the project (e.g., cargo, go, or compiler flags) rather than system-level package managers.

## 🚀 Installation Considerations

### For Intel MacBook
```bash
# Install packages via Homebrew or the repo bootstrap
brew install <package>
# or
cd ~/dotfiles
./install.sh --machine macbook
```

### For Apple Silicon Mac Mini
```bash
# Install packages via Homebrew (ARM) or run repo bootstrap for macmini profile
brew install <package>
# or
cd ~/dotfiles
./install.sh --machine macmini
```

## ⚙️ Machine-specific configuration

Instead of a system-wide declarative Nix config, we prefer small per-machine scripts and the repository `Brewfile` to handle package differences. For example, add a `scripts/machines/macmini.sh` that installs ARM-specific packages and tweaks.

Use `./install.sh --machine <name>` to apply per-machine package lists and configuration.

## 🔧 Troubleshooting Architecture Issues

### "Unsupported architecture" Error
```bash
# Check binary compatibility
file $(which kanata)
# If the binary doesn't match your architecture, install the correct variant via Homebrew or download a release.
```

### Binary Cache / Package availability
If a package is unavailable for your architecture via Homebrew, consider installing the Intel (x86) version under Rosetta or building from source with the appropriate toolchain.

### Mixed Architecture Development

If developing for multiple architectures, use your project's toolchain (cargo, go, etc.) for cross-compilation and test on CI or a VM/emulator.

## 📊 Performance Comparison

| Operation | Intel MacBook | Apple Silicon M4 |
|-----------|---------------|------------------|
| **Simple tool run** | ~2-3s | ~1-2s (faster) |
| **Build simple package** | ~5-10s | ~3-5s (faster) |
| **Rosetta emulation** | N/A | ~50% overhead |
| **Native execution** | Fast | Very fast |

## 🎯 Best Practices

1. **Use native system** - Always match machine architecture
   ```bash
   # Ensure you install the correct package variants for your architecture
   # e.g. via Homebrew or the repo bootstrap:
   cd ~/dotfiles
   ./install.sh --machine macmini
   ```

2. **Cache strategy** - Prefer official binary caches for package managers (Homebrew uses bottles)
   ```bash
   # Inspect package availability via Homebrew
   brew info <package>
   ```
   ```

3. **Conditional packages** - Use machine-specific optimizations
   ```bash
   # Example per-machine package install (scripts/machines/macmini.sh)
   brew install package1 package2
   # Or add machine-specific packages to the Brewfile or install.sh
   ```

4. **Pin package lists** - Pin package versions for consistency (use `Brewfile` or lock specific package versions)
   ```bash
   # Update Brewfile or package lock file, then commit
   git add Brewfile
   git commit -m "chore: update Brewfile"
   ```

## 📚 Resources

- [NixOS Wiki - Darwin (legacy)](https://nixos.wiki/wiki/Nix_on_Apple_Silicon)  # archival reference
- [Nix Darwin Issues (legacy)](https://github.com/lnl7/nix-darwin/issues)
- [Nixpkgs Architecture Support (legacy)](https://nixos.org/manual/nixpkgs/stable/#chap-meta)
- [Apple Silicon Support (legacy)](https://github.com/NixOS/nixpkgs/labels/aarch64-darwin)
