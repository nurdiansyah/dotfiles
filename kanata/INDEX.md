# Kanata Files Index

Quick reference to all files in the Kanata configuration directory.

## 📚 Documentation Files

### [README.md](README.md)
**Complete documentation** for Kanata
- What is Kanata and why use it
- Full installation instructions for macOS
- Comprehensive configuration guide
- Common use cases and examples
- Troubleshooting guide
- Advanced features documentation

**Start here if:** You want to understand everything about Kanata.

### [QUICKSTART.md](QUICKSTART.md)
**5-minute quick start guide**
- Fastest way to get started
- Basic testing instructions
- Simple customization examples
- Emergency stop instructions

**Start here if:** You just want to get Kanata running quickly.

### [INSTALL-MACOS.md](INSTALL-MACOS.md)
**macOS-specific installation guide for Tahoe machine**
- Detailed prerequisites for macOS
- Step-by-step installation using Nix Darwin
- macOS permission setup (Accessibility, Input Monitoring)
- Autostart configuration
- macOS-specific troubleshooting
- Complete verification checklist

**Start here if:** You're installing on a fresh macOS system.

## ⚙️ Configuration Files

### [kanata.kbd](kanata.kbd)
**Main Kanata configuration file**
- Default keyboard layout mappings
- Caps Lock → Escape/Control behavior
- Navigation layer (arrow keys via H/J/K/L)
- Function key mappings
- Base configuration for daily use

**Edit this file** to customize your keyboard remappings.

### [examples.kbd](examples.kbd)
**Advanced configuration examples**
- Multiple layers (QWERTY, Colemak, symbols, etc.)
- Window management shortcuts
- Application launcher layer
- Home row mods
- Tap-dance configurations
- Chord definitions
- Macros and one-shot modifiers
- Advanced techniques reference

**Reference this file** when adding advanced features to your config.

## 🔧 Utility Scripts

### [verify-setup.sh](verify-setup.sh)
**Installation verification script**
- Checks if Kanata is installed
- Validates configuration files
- Tests config syntax
- Verifies file permissions
- Checks LaunchAgent status

**Run this** after installation to ensure everything is set up correctly.

```bash
~/.dotfiles/kanata/verify-setup.sh
```

### [setup-launchagent.sh](setup-launchagent.sh)
**Automatic startup configuration**
- Creates macOS LaunchAgent
- Configures Kanata to start at login
- Validates configuration before setup
- Automatically loads the service

**Run this** to make Kanata start automatically when you log in.

```bash
~/.dotfiles/kanata/setup-launchagent.sh
```

### [remove-launchagent.sh](remove-launchagent.sh)
**LaunchAgent removal script**
- Stops running Kanata service
- Removes LaunchAgent configuration
- Optionally cleans up log files
- Preserves main configuration

**Run this** to stop Kanata from starting automatically.

```bash
~/.dotfiles/kanata/remove-launchagent.sh
```

## 📋 Quick Command Reference

### First-Time Setup
```bash
# 1. Install via Nix Darwin (if not already installed)
cd ~/.dotfiles
darwin-rebuild switch --flake .#macmini

# 2. Verify installation
~/.dotfiles/kanata/verify-setup.sh

# 3. Test manually first
kanata -c ~/.dotfiles/kanata/kanata.kbd

# 4. Set up autostart (optional)
~/.dotfiles/kanata/setup-launchagent.sh
```

### Daily Use
```bash
# Start Kanata manually
kanata -c ~/.dotfiles/kanata/kanata.kbd

# Check if Kanata is running
pgrep kanata

# Stop Kanata
pkill kanata

# View logs
tail -f /tmp/kanata.log
tail -f /tmp/kanata.err
```

### Configuration Management
```bash
# Edit main config (use your preferred editor)
${EDITOR:-nvim} ~/.dotfiles/kanata/kanata.kbd

# Validate config syntax
kanata -c ~/.dotfiles/kanata/kanata.kbd --check

# Reload after changes
pkill kanata && kanata -c ~/.dotfiles/kanata/kanata.kbd &

# Commit changes to git
cd ~/.dotfiles
git add kanata/
git commit -m "Update Kanata configuration"
git push
```

### LaunchAgent Management
```bash
# Check LaunchAgent status
launchctl list | grep kanata

# Manually stop LaunchAgent
launchctl unload ~/Library/LaunchAgents/com.kanata.plist

# Manually start LaunchAgent
launchctl load ~/Library/LaunchAgents/com.kanata.plist

# View LaunchAgent logs
tail -f /tmp/kanata.log
```

## 🎯 Where to Start?

### I'm new to Kanata
→ Read [QUICKSTART.md](QUICKSTART.md) first (5 minutes)

### I want to install on macOS
→ Follow [INSTALL-MACOS.md](INSTALL-MACOS.md)

### I want detailed documentation
→ Read [README.md](README.md)

### I want advanced features
→ Check [examples.kbd](examples.kbd)

### I want to customize
→ Edit [kanata.kbd](kanata.kbd)

### I want auto-startup
→ Run [setup-launchagent.sh](setup-launchagent.sh)

## 🔗 External Resources

- [Kanata GitHub Repository](https://github.com/jtroo/kanata)
- [Kanata Configuration Reference](https://github.com/jtroo/kanata/blob/main/docs/config.adoc)
- [Community Examples](https://github.com/jtroo/kanata/tree/main/cfg_samples)
- [GitHub Discussions](https://github.com/jtroo/kanata/discussions)

## 📝 File Summary Table

| File | Type | Purpose | When to Use |
|------|------|---------|-------------|
| README.md | Doc | Complete documentation | Full reference |
| QUICKSTART.md | Doc | Quick start guide | First run |
| INSTALL-MACOS.md | Doc | macOS installation | New installation |
| INDEX.md | Doc | This file - directory map | Finding files |
| kanata.kbd | Config | Main keyboard config | Daily use/editing |
| examples.kbd | Config | Advanced examples | Learning features |
| verify-setup.sh | Script | Setup verification | After install |
| setup-launchagent.sh | Script | Auto-startup setup | One-time setup |
| remove-launchagent.sh | Script | Remove auto-startup | Disable service |

## 🏗️ Directory Structure

```
~/.dotfiles/kanata/
├── README.md                  # Complete documentation
├── QUICKSTART.md              # Quick start guide
├── INSTALL-MACOS.md           # macOS installation guide
├── INDEX.md                   # This file - directory map
├── kanata.kbd                 # Main configuration
├── examples.kbd               # Advanced examples
├── verify-setup.sh            # Verification script
├── setup-launchagent.sh       # Auto-startup script
└── remove-launchagent.sh      # Removal script
```

## 💾 Logs and Runtime Files

Kanata creates these files at runtime:

```
/tmp/kanata.log                # Standard output log
/tmp/kanata.err                # Error log
~/Library/LaunchAgents/com.kanata.plist  # LaunchAgent (if set up)
```

---

**Need help?** Start with [QUICKSTART.md](QUICKSTART.md) or [README.md](README.md)!
