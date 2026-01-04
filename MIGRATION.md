# Migration Guide: Bash → Nix Darwin

This guide helps migrate from the old bash `install.sh` to the new Nix Darwin declarative system.

## 🔄 What's Changing

| Aspect | Old (Bash) | New (Nix Darwin) |
|--------|-----------|-----------------|
| **Installation** | `bash install.sh` | `bash install-nix.sh` |
| **Config Language** | Bash scripts | Nix language (declarative) |
| **Package Management** | Homebrew (manual) | Nix + Homebrew integration |
| **Shell Config** | `~/.zshrc` symlink | Home Manager generated |
| **System Config** | Manual defaults | darwin/configuration.nix |
| **Version Control** | Manual tracking | flake.lock (auto-tracked) |
| **Rollback** | Manual backup | `darwin-rebuild` generations |
| **Updates** | Manual sync | `nix flake update` |

## 📋 Pre-Migration

1. **Backup current config**
   ```bash
   cp ~/.zshrc ~/.zshrc.backup
   cp ~/.config/nvim ~/.config/nvim.backup
   mkdir -p ~/.dotfiles_migration_backup
   cp -r ~/.config ~/.dotfiles_migration_backup/
   ```

2. **Document current setup**
   ```bash
   brew list > ~/brew-packages.txt
   brew list --cask > ~/brew-casks.txt
   npm list -g --depth=0 > ~/npm-global.txt
   ```

3. **Check Nix compatibility**
   ```bash
   nix run nixpkgs#nixpkgs-review -- --help
   ```

## 🚀 Migration Steps

### Step 1: Install Nix
```bash
# If not installed
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Verify
nix --version
```

### Step 2: Enable Flakes
```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# Verify
nix --version --json | jq '.version'

# Check architecture (important for picking the correct machine flake target)
uname -m           # 'x86_64' for Intel, 'arm64' for Apple Silicon
nix eval --impure --expr builtins.currentSystem
```

### Step 3: Update Dotfiles
```bash
cd ~/.dotfiles
git pull origin main

# Verify Nix files exist
ls -la flake.nix darwin/ home/
```

### Step 4: Install Nix Darwin
```bash
# Test configuration (dry-run) - target a machine (macbook or macmini)
darwin-rebuild check --flake ~/.dotfiles#macbook    # Intel
darwin-rebuild check --flake ~/.dotfiles#macmini    # Apple Silicon M4

# If OK, apply (pick the appropriate target)
darwin-rebuild switch --flake ~/.dotfiles#macbook
# or
# darwin-rebuild switch --flake ~/.dotfiles#macmini
```

### Step 5: Verify Installation
```bash
# Show current generation
darwin-rebuild info

# List recent generations
darwin-rebuild list-generations | head -5

# Test shell
exec zsh

# Quick verification
uname -m                  # confirm architecture
nix profile list          # show user profiles & installed packages
nix-store -q --requisites /run/current-system || true  # verify system requisites
brew list --cask || true  # check casks (if using Homebrew alongside Nix)
```

## ⚙️ Configuration Migration

### From Bash install.sh
Old approach:
- `install.sh` checked package manager
- Symlinked individual files
- Manual environment setup

New approach:
- `flake.nix` declares all dependencies
- Home Manager generates configs
- Nix manages versions

### Custom Packages

#### Old Way (Homebrew)
```bash
# In ~/.zsh_profile
export PATH="/usr/local/opt/mypackage/bin:$PATH"
```

#### New Way (Nix)
Add to `darwin/configuration.nix`:
```nix
environment.systemPackages = with pkgs; [
  mypackage
];
```

Or `home/home.nix` for user packages:
```nix
home.packages = with pkgs; [
  mypackage
];
```

Then run:
```bash
# Use a machine-specific target, e.g.:
darwin-rebuild switch --flake ~/.dotfiles#macbook
# or
# darwin-rebuild switch --flake ~/.dotfiles#macmini
```

### Shell Aliases

#### Old Way (.zshrc)
```bash
alias g='git'
alias k='kubectl'
```

#### New Way (home/zsh/init.zsh)
Add to function, then rebuild.

## 🔧 Troubleshooting Migration

### Problem: "flakes not enabled"
**Solution:**
```bash
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
```

### Problem: "darwin-rebuild: command not found"
**Solution:**
```bash
# Run via nix run; specify the machine target you want to apply
nix run nix-darwin -- switch --flake ~/.dotfiles#macbook
# or
# nix run nix-darwin -- switch --flake ~/.dotfiles#macmini
```

### Problem: Permission denied on /nix
**Solution:** Nix installer handles this, but if issues:
```bash
sudo launchctl stop org.nixos.nix-daemon
sudo launchctl start org.nixos.nix-daemon
```

### Problem: Home Manager conflicts
**Solution:**
```bash
# Reset home-manager (careful!)
rm -rf ~/.config/home-manager ~/.local/state/home-manager
# Rebuild for your machine target, e.g.:
darwin-rebuild switch --flake ~/.dotfiles#macbook
# or
# darwin-rebuild switch --flake ~/.dotfiles#macmini
```

### Problem: Old ~/.zshrc conflicts
**Solution:**
```bash
# Home Manager generates this now, remove old one
rm ~/.zshrc ~/.zsh_profile

# Rebuild to regenerate (target your machine)
darwin-rebuild switch --flake ~/.dotfiles#macbook
# or
# darwin-rebuild switch --flake ~/.dotfiles#macmini
```

## 🔄 Staying in Sync

### With Git
```bash
# Pull changes
cd ~/.dotfiles
git pull origin main

# Apply new config
# Use the machine target you intend to update, for example:
darwin-rebuild switch --flake .#macbook
# or
# darwin-rebuild switch --flake .#macmini
```

### Update Dependencies
```bash
# Update all inputs to latest
cd ~/.dotfiles
nix flake update

# Test locally (dry-run) - use per-machine target as needed
darwin-rebuild check --flake .#macbook
# or
darwin-rebuild check --flake .#macmini

# Apply changes when satisfied
darwin-rebuild switch --flake .#macbook

# If everything passes, commit the updated lockfile
git add flake.lock
git commit -m "chore: update flake inputs"
```

## 📊 Migration Checklist

- [ ] Install Nix
- [ ] Enable flakes
- [ ] Update dotfiles repo
- [ ] Run `darwin-rebuild check` (dry-run)
- [ ] Run `darwin-rebuild switch` (apply)
- [ ] Verify shell: `exec zsh`
- [ ] Test Neovim: `nvim --version`
- [ ] Test profile: `nvim_profile_show`
- [ ] Test Git: `git --version`
- [ ] Test Kubernetes: `kubectl version`
- [ ] Remove old config files if needed
- [ ] Commit changes: `git add flake.lock && git commit`

## ✅ Post-Migration

### Clean Up Old Files
```bash
# If no issues, remove old zsh files
rm -f ~/.zshrc.backup ~/.zsh_profile.backup

# Remove old nvim backup if everything works
rm -rf ~/.config/nvim.backup

# Keep general backup
# rm -rf ~/.dotfiles_migration_backup (after 2 weeks)
```

### Set Nvim Profile
```bash
nvim_profile javascript    # or java, devops
nvim_profile_show
```

### Update Documentation
- [ ] Update README with new commands
- [ ] Add custom aliases to dotfiles
- [ ] Document any machine-specific configs in `~/.zsh_local`

## 🎯 Benefits After Migration

✅ **Reproducible** - Exact same environment on any machine
✅ **Faster** - Nix caches everything
✅ **Safer** - Rollback instant if something breaks
✅ **Cleaner** - No symlink spaghetti
✅ **Versioned** - All dependencies in flake.lock
✅ **Declarative** - Config is easier to read and share

## 📞 Support

If issues during migration:
1. Check `darwin-rebuild` output for error messages
2. Review [Nix Darwin docs](https://github.com/lnl7/nix-darwin)
3. Try rollback: `darwin-rebuild switch --profile /nix/var/nix/profiles/system-<N>-link`
4. Ask in [NixOS Discourse](https://discourse.nixos.org/)

## 🔐 Security Notes

- Nix keeps older generations for safety
- Flake.lock prevents supply chain attacks via pinned versions
- **Secrets:** Do NOT commit tokens/credentials to the repo. Store secrets in the macOS Keychain, environment variables, or a local file like `~/.zsh_local` (which must be gitignored). Consider using tools like `pass`, `1password`, or `secret-service` integrations.
- All configs are plaintext and reviewable
