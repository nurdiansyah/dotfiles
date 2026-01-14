# Multi-Machine Configuration

Support untuk multiple macOS machines dengan berbeda architecture:
- **MacBook** = Intel (x86_64)
- **Mac Mini** = Apple Silicon M4 (aarch64)

## 🖥️ Supported Machines

| Machine | CPU | Architecture | System | Hostname |
|---------|-----|--------------|--------|----------|
| **MacBook** | Intel | x86_64-darwin | `x86_64-darwin` | nurdiansyah-macbook |
| **Mac Mini** | Apple Silicon M4 | aarch64-darwin | `aarch64-darwin` | nurdiansyah-macmini |

## 📁 Configuration Structure

This file historically documented a Nix/nix-darwin-based multi-machine configuration (flakes + darwin modules). Nix support has been removed from active maintenance in this repository — the previous Nix artifacts were removed or archived. Use the repository `Brewfile` and `install.sh` for Homebrew-based installation and machine bootstrapping instead.


## 🚀 Installation

### First Time Setup

For a non-Nix setup, use the repository's `Brewfile` and `install.sh` to bootstrap Homebrew packages and user configuration.

Script akan:
1. ✅ Detect machine type (atau tanya user)
2. ✅ Apply configuration untuk machine tersebut
3. ✅ Show next steps

### Manual Setup

Non-Nix workflows: use the repository bootstrap and per-machine scripts.

```bash
# Bootstrap packages and per-machine configuration (preferred)
cd ~/dotfiles
./install.sh

# Or run any per-machine helper script you maintain (example)
# bash scripts/setup-machine.sh macmini
```

## 🔄 Switching Between Machines

If you used to use Nix/darwin flakes, that workflow is now archived. For switching machine profiles, prefer small per-machine scripts or manual steps using the repo bootstrap, for example:

```bash
# Re-run the bootstrap with machine detection or pass a machine argument (example)
cd ~/dotfiles
./install.sh --machine macmini
```

Hostname akan automatically update sesuai konfigurasi.

## 🔧 Customization per Machine

### Add Machine-Specific Packages

Use per-machine scripts or the `Brewfile` to define machine-specific packages.

Example `scripts/machines/macbook.sh`:

```bash
#!/usr/bin/env bash
# MacBook-specific package list
brew install tlp # power management tool (example)
brew install some-macbook-only-tool
```

Example `scripts/machines/macmini.sh`:

```bash
#!/usr/bin/env bash
# Mac Mini-specific package list
brew install some-macmini-only-tool
```

Or add conditional logic to `install.sh` that applies per-machine Brewfile fragments.

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
  - Recommended parallel build jobs: 4 (conservative for laptop)
  - SSD-optimized

### Mac Mini Configuration (Apple Silicon M4)
- **Hostname:** nurdiansyah-macmini
- **Architecture:** aarch64-darwin (ARM64)
- **Type Key:** macmini
- **CPU:** Apple Silicon M4 (aarch64)
- **Use Case:** Desktop development
- **Special Config:**
  - Recommended parallel build jobs: 8 (desktop)
  - Rosetta x86_64 fallback support
  - ARM64-native packages prioritized
  - More aggressive caching

## 📝 Adding New Machine

### Step 1: Define a new machine profile

This repository no longer maintains Nix flakes for machine configuration. To add a new machine, add a small per-machine script or update the install bootstrap to accept/handle a new machine profile.

Example: add `scripts/machines/macstudio.sh` or extend `install.sh` to handle a `macstudio` profile with the necessary package lists and setup steps.

### Step 2: Add per-machine setup

Create a per-machine script or extend `install.sh` to handle architecture-specific package lists and settings. Example:

```bash
# scripts/machines/macstudio.sh
#!/usr/bin/env bash
# Install packages for MacStudio (M2/M4)
brew install package1 package2
# Tune parallel build jobs for local builds if needed
export MAX_JOBS=10
```

### Step 3: Apply

```bash
# Run the repository bootstrap which will detect machine or apply a specific profile
cd ~/dotfiles
./install.sh --machine macstudio
# Or run the per-machine setup script
# bash scripts/machines/macstudio.sh
```

## 🎯 Checking Current Machine

```bash
# Show current hostname
hostname

# Show which machine type is active (repo-specific file)
cat ~/.config/nvim/state/profile 2>/dev/null || echo "default"
```

## 📋 Common Commands

```bash
# Apply repository bootstrap (preferred)
cd ~/dotfiles
./install.sh

# Apply specific machine (if supported)
./install.sh --machine macbook

# Show available machine profiles (repo-specific)
ls scripts/machines || echo "No per-machine scripts present"

# Update packages via bootstrap or Brewfile
cd ~/dotfiles
./install.sh --update

# Rollback or restore from git
git checkout -- <file>
```

## 🔍 Debugging

### Show current configuration
```bash
# Repository-based machine profiles (if present)
ls scripts/machines || echo "No per-machine scripts present"

# Check what the bootstrap will install (Brewfile)
cat Brewfile | sed -n '1,120p'

# Show machine-specific config (repo convention)
cat ~/.config/nvim/state/profile 2>/dev/null || echo "default"
```

### Test configuration
```bash
# Dry-run the repo bootstrap (if supported)
cd ~/dotfiles
./install.sh --dry-run

# Run install with verbose logging (example)
./install.sh --machine macbook --verbose

# Inspect Brewfile to see what will be installed
cat Brewfile | sed -n '1,120p'
```

## 🚨 Troubleshooting

### Configuration errors
```bash
# Check your repo files and bootstrap scripts for issues
cd ~/dotfiles
git status
# Inspect scripts/machines or Brewfile for missing entries
ls scripts/machines Brewfile || true
```

### Machine not switching
```bash
# Check bootstrap or script logs for errors
cd ~/dotfiles
./install.sh --machine macbook --verbose

# Or run per-machine helper script and inspect output
bash scripts/machines/macbook.sh || true
# Use git to rollback changes if needed
git checkout -- scripts/machines/macbook.sh
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

The Nix/Home Manager examples previously included here have been removed as Home Manager is no longer maintained in this repository. For machine-specific package installation and configuration, prefer using per-machine scripts or the `Brewfile` and `install.sh` flow. If you need to reintroduce per-machine declarative config, consider adding small scripts under `scripts/` or a documented convention in this repository.


## 🔐 Security Notes

- Flake.lock pinned untuk reproducibility
- Machine-specific configs tidak menyimpan secrets
- Use `~/.zsh_local` untuk machine-specific tokens
- Git track flake.lock untuk sync antar machines

## 💡 Pro Tips

1. **Sync dengan Git** - Commit changes to the repo and any package files (Brewfile) after updates
   ```bash
   git add Brewfile
   git commit -m "chore: update Brewfile"
   ```

2. **Use same config** - Keep a shared baseline and override only what's necessary
   ```bash
   # Share sebagian besar, override hanya yang perlu
   ```

3. **Test perubahan** - Test bootstrap on a test machine or VM before applying widely
   ```bash
   ./install.sh --dry-run
   ```

4. **Keep history** - Use git for rollback and versions
   ```bash
   git checkout -- <file>
   ```
