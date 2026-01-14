# Kanata Installation on macOS (Tahoe)

Specific installation instructions for the Tahoe macOS machine.

## 📋 Machine Information

- **Machine Name:** Tahoe
- **OS:** macOS
- **Installation Method:** Homebrew / Manual
- **Package Manager:** Homebrew

## ✅ Prerequisites

### 1. Install Karabiner VirtualHIDDevice Driver (REQUIRED)

**IMPORTANT:** Kanata on macOS requires the Karabiner VirtualHIDDevice driver to function. This is a separate component from Karabiner-Elements.

#### For macOS 11 (Big Sur) and newer:

The supported Karabiner driver version is **v6.2.0**.

1. Download and install the Karabiner DriverKit VirtualHIDDevice driver v6.2.0:
   - Visit: https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases
   - Download version v6.2.0 (or the version specified in the latest Kanata release)
   - Follow the installation instructions

2. **Important notes:**
   - Please read: https://github.com/jtroo/kanata/issues/1264#issuecomment-2763085239
   - Also see: https://github.com/jtroo/kanata/discussions/1537
   - **WARNING:** macOS does not support mouse input in Kanata. Mouse button actions (`mbck`, `mfwd`) are not operational.

#### For macOS 10 (Catalina and older):

1. Install the Karabiner kernel extension:
   - Visit: https://github.com/pqrs-org/Karabiner-VirtualHIDDevice
   - Download and install the appropriate version for your macOS

### 3. Install Kanata

Install Kanata using Homebrew (preferred) or download the binary from GitHub releases:

```bash
# Homebrew (preferred)
brew install kanata

# Or use this repository's bootstrap (installs Brewfile packages)
cd ~/dotfiles
./install.sh
```

If you installed Kanata by other means, ensure `kanata` is in your PATH.

### 4. Verify Dotfiles Clone

Ensure the dotfiles repository is cloned:

```bash
# Check if dotfiles exist
ls ~/dotfiles

# Should show: kanata/, scripts/, Brewfile, etc.
```

### 5. System Permissions

macOS requires special permissions for keyboard remapping tools:

#### Grant Accessibility Permission

1. Open **System Settings** (or System Preferences on older macOS)
2. Navigate to **Privacy & Security**
3. Click on **Accessibility** (left sidebar)
4. Click the lock icon 🔒 to make changes (enter password)
5. Click the **+** button to add applications
6. Add your terminal application:
   - Kitty: `/Applications/Kitty.app`
   - iTerm2: `/Applications/iTerm2.app`
   - Terminal: `/System/Applications/Utilities/Terminal.app`
   - Ghostty: `/Applications/Ghostty.app`

#### Grant Input Monitoring Permission

1. In **System Settings** → **Privacy & Security**
2. Click on **Input Monitoring** (left sidebar)
3. Add your terminal application (same as above)

**Note:** You may need to restart your terminal app after granting permissions.

## 🚀 Installation Steps

### Step 1: Install Kanata

Install the Kanata binary using Homebrew or download it from GitHub releases:

```bash
# Homebrew (preferred)
brew install kanata

# Or use this repository's bootstrap (installs Brewfile packages)
cd ~/dotfiles
./install.sh
```

This will provide the `kanata` binary available in your PATH.

**About Binary Variants:**
- The Nix package will install the appropriate binary for your system architecture
- **x64/x86_64**: For Intel Macs
- **arm64/aarch64**: For Apple Silicon (M1/M2/M3/M4)
- The Nix version includes `cmd_allowed` functionality (allows `cmd` actions in config)

### Step 2: Verify Installation

Check that Kanata is installed:

```bash
# Check if kanata is in PATH
which kanata
# Should output path to the kanata binary (e.g., /opt/homebrew/bin/kanata or /usr/local/bin/kanata)

# Check version
kanata --version

# Verify the binary
file $(which kanata)
# Should show: Mach-O 64-bit executable
```

### Step 3: Test Configuration

Test that your configuration file is valid:

```bash
# Preferred (XDG):
kanata -c ~/.config/kanata/kanata.kbd --check

# Or fallback (repo layout):
# kanata -c ~/dotfiles/kanata/kanata.kbd --check
```

If there are no errors, the configuration is valid!

### Step 4: First Run

**IMPORTANT:** Kanata on macOS requires sudo/root privileges to access the keyboard device.

Start Kanata manually for the first test:

```bash
# Run with sudo (required on macOS)
sudo kanata -c ~/.config/kanata/kanata.kbd
# Fallback (repo layout):
# sudo kanata -c ~/dotfiles/kanata/kanata.kbd
```

**Note:** You'll need to enter your password. Kanata needs root access to interact with the Karabiner driver.

You should see output like:
```
kanata v1.x.x starting
Parsing config file: ~/.config/kanata/kanata.kbd
Config file is valid
Starting...
```

**Test the configuration:**
1. Try tapping Caps Lock (should act as Escape)
2. Hold Caps Lock and press H/J/K/L (should be arrow keys)

**If it works:** Great! Press `Ctrl+C` to stop and proceed to setup autostart.

**If it doesn't work:** Check the [Troubleshooting](#troubleshooting) section.

## 🔄 Setting Up Autostart

Choose one of the following methods to run Kanata automatically:

### Method 1: LaunchDaemon (Recommended for macOS)

Since Kanata requires sudo/root access on macOS, we need to use a LaunchDaemon (not LaunchAgent):

**IMPORTANT:** LaunchDaemons run as root and start before user login.

```bash
# Get the Kanata binary path
KANATA_BIN=$(which kanata)
# Prefer XDG config (recommended)
CONFIG_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/kanata/kanata.kbd"
if [ ! -f "$CONFIG_PATH" ] && [ -f "$HOME/dotfiles/kanata/kanata.kbd" ]; then
  CONFIG_PATH="$HOME/dotfiles/kanata/kanata.kbd"
fi

# Create launch daemon (requires sudo)
sudo tee /Library/LaunchDaemons/com.kanata.plist > /dev/null <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.kanata</string>
    <key>ProgramArguments</key>
    <array>
        <string>${KANATA_BIN}</string>
        <string>-c</string>
        <string>${CONFIG_PATH}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/kanata.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/kanata.err</string>
</dict>
</plist>
PLIST

# Set proper permissions
sudo chown root:wheel /Library/LaunchDaemons/com.kanata.plist
sudo chmod 644 /Library/LaunchDaemons/com.kanata.plist

# Load the launch daemon
sudo launchctl load /Library/LaunchDaemons/com.kanata.plist

# Verify it's running
sudo launchctl list | grep kanata
ps aux | grep kanata
```

**Managing the LaunchDaemon:**

```bash
# Stop Kanata
sudo launchctl unload /Library/LaunchDaemons/com.kanata.plist

# Start Kanata
sudo launchctl load /Library/LaunchDaemons/com.kanata.plist

# Check logs
tail -f /tmp/kanata.log
tail -f /tmp/kanata.err
```

**Note:** The provided `setup-launchagent.sh` script creates a LaunchAgent, not a LaunchDaemon. For proper sudo access, manually create a LaunchDaemon as shown above.

### Method 2: Shell Startup (Alternative - Not Recommended)

**Note:** This method requires entering your password each time you open a terminal, which is not ideal.

Add to your `~/.zshrc` (or `~/.bashrc`):

```bash
# Add this to the end of the file (requires password on each terminal launch)
if ! pgrep -x "kanata" > /dev/null; then
    echo "Starting Kanata (requires sudo password)..."
    sudo kanata -c ~/.config/kanata/kanata.kbd > /tmp/kanata.log 2>&1 &
fi
```

Then reload your shell:
```bash
source ~/.zshrc
```

### Method 3: Manual Start (Testing)

For testing or occasional use:

```bash
# Start in foreground (requires sudo)
sudo kanata -c ~/.config/kanata/kanata.kbd

# Or start in background
sudo kanata -c ~/.config/kanata/kanata.kbd &

# Stop background process
sudo pkill kanata
```

## 🧪 Testing Your Setup

### Basic Functionality Test

1. **Test Caps Lock → Escape:**
   - Open a text editor
   - Tap Caps Lock quickly
   - Should act as Escape (in vim, exits insert mode)

2. **Test Caps Lock → Control:**
   - Hold Caps Lock and press C
   - Should copy text (Cmd+C equivalent in many contexts)

3. **Test Navigation Layer:**
   - Hold Caps Lock
   - Press H, J, K, L
   - Should move cursor like arrow keys

4. **Test Function Keys:**
   - Press F1/F2 for brightness
   - Press F10/F11/F12 for volume

### Performance Test

Check that Kanata isn't using excessive resources:

```bash
# Check CPU usage
top -l 1 | grep kanata

# Should be < 1% CPU when idle
# Should be < 5% CPU when actively typing
```

## 🔧 Troubleshooting

### Kanata Not Starting

**Error: "Failed to open device"**

→ **Solution:** Grant Accessibility permissions (see Prerequisites)

**Error: "Permission denied"**

→ **Solution:** 
```bash
# Make sure kanata binary is executable
chmod +x $(which kanata)

# Or reinstall (Homebrew)
brew reinstall kanata
# Or re-run repo bootstrap:
cd ~/dotfiles
./install.sh
```

**Error: "Config file not found"**

→ **Solution:** Verify the path:
```bash
# Preferred:
ls -la ~/.config/kanata/kanata.kbd
# Fallback:
ls -la ~/dotfiles/kanata/kanata.kbd
```

### Move config to XDG (recommended)

```bash
# Create XDG dir and symlink repo config
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}"
ln -sfn "$HOME/dotfiles/kanata" "${XDG_CONFIG_HOME:-$HOME/.config}/kanata"
# OR use the helper script:
bash ~/dotfiles/kanata/link-config.sh
```

### Kanata Running But Keys Not Remapping

1. **Check if Kanata is actually running:**
   ```bash
   ps aux | grep kanata
   ```

2. **Check the logs:**
   ```bash
   tail -f /tmp/kanata.log
   tail -f /tmp/kanata.err
   ```

3. **Verify permissions again:**
   - System Settings → Privacy & Security → Accessibility
   - Make sure your terminal app has a checkmark ✓

4. **Restart Kanata:**
   ```bash
   pkill kanata
   kanata -c ~/.config/kanata/kanata.kbd
   ```

### Configuration Errors

**Error: "Parse error" or "Invalid configuration"**

→ **Solution:** Check your configuration syntax:
```bash
kanata -c ~/.config/kanata/kanata.kbd --check
```

Common issues:
- Missing parentheses
- Typos in key names
- Unmatched quotes in macros

### Conflicts with Other Software

If you have other keyboard remapping software:

- **Karabiner-Elements:** Conflicts with Kanata. Choose one.
- **BetterTouchTool:** May conflict. Try disabling BTT keyboard features.
- **Hammerspoon:** Can coexist but test carefully.

### High CPU Usage

If Kanata is using a lot of CPU:

1. **Check for config loops:**
   ```bash
   # Review your config for circular dependencies
   nvim ~/.config/kanata/kanata.kbd
   ```

2. **Update to latest version:**
   ```bash
   # If installed via Homebrew
   brew upgrade kanata

   # Or re-run repo bootstrap
   cd ~/dotfiles
   ./install.sh
   ```

### Debugging with Verbose Output

For detailed debugging information:

```bash
# Run with verbose/debug output
kanata -c ~/.config/kanata/kanata.kbd -d

# Or check system logs
log show --predicate 'processImagePath contains "kanata"' --last 1h
```

## 📊 Verification Checklist

After installation, verify everything is working:

- [ ] Kanata binary is installed (`which kanata` shows path)
- [ ] Configuration file exists (`ls ~/.config/kanata/kanata.kbd`)
- [ ] (fallback) Configuration file exists (`ls ~/dotfiles/kanata/kanata.kbd`)
- [ ] Configuration is valid (`kanata -c ... --check` succeeds)
- [ ] Accessibility permission granted
- [ ] Input Monitoring permission granted
- [ ] Kanata runs without errors
- [ ] Caps Lock tap → Escape works
- [ ] Caps Lock hold → Control works
- [ ] Caps Lock + H/J/K/L → Arrow keys work
- [ ] Function keys work (brightness, volume)
- [ ] Kanata starts automatically (if using LaunchAgent)
- [ ] CPU usage is reasonable (< 5%)

## 🔄 Updating Kanata

To update Kanata to the latest version:

```bash
# If installed via Homebrew
brew upgrade kanata

# Or re-run repo bootstrap to update packages
cd ~/dotfiles
./install.sh

# Restart Kanata (if needed)
launchctl unload ~/Library/LaunchAgents/com.kanata.plist
launchctl load ~/Library/LaunchAgents/com.kanata.plist
```

## 📝 Configuration Management

Your Kanata configuration is managed in git:

```bash
cd ~/dotfiles

# See what's changed
git status

# Commit changes
git add kanata/
git commit -m "Update Kanata configuration"

# Push to remote
git push origin main

# Pull latest changes on another machine
git pull origin main
```

## 🚀 Next Steps

Now that Kanata is installed:

1. **Read the Quick Start:** See [QUICKSTART.md](QUICKSTART.md)
2. **Review the configuration:** Edit `~/.config/kanata/kanata.kbd` (or `~/dotfiles/kanata/kanata.kbd` if using fallback)
3. **Test extensively:** Use for a few days before heavy customization
4. **Check examples:** See [examples.kbd](examples.kbd) for advanced features
5. **Customize:** Adjust to match your workflow

## 📚 Additional Resources

- [Full Documentation](README.md) - Complete feature guide
- [Quick Start](QUICKSTART.md) - Get started in 5 minutes
- [Examples](examples.kbd) - Advanced configuration examples
- [Kanata GitHub](https://github.com/jtroo/kanata) - Official repository
- [Configuration Guide](https://github.com/jtroo/kanata/blob/main/docs/config.adoc) - Detailed config syntax

## 🆘 Getting Help

If you encounter issues:

1. Check the [Troubleshooting](#troubleshooting) section above
2. Review Kanata logs: `/tmp/kanata.log` and `/tmp/kanata.err`
3. Check [Kanata GitHub Issues](https://github.com/jtroo/kanata/issues)
4. Ask in [Kanata Discussions](https://github.com/jtroo/kanata/discussions)

---

**Installation complete!** 🎉 You should now have Kanata running on your macOS (Tahoe) machine.
