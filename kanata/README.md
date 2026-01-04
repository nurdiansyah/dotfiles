# Kanata Configuration

Kanata is a cross-platform software keyboard remapper that improves keyboard ergonomics through advanced remapping capabilities.

## 📋 Table of Contents

- [What is Kanata?](#what-is-kanata)
- [Installation on macOS (Tahoe)](#installation-on-macos-tahoe)
- [Configuration](#configuration)
- [Usage](#usage)
- [Common Use Cases](#common-use-cases)
- [Troubleshooting](#troubleshooting)
- [References](#references)

## 🎯 What is Kanata?

Kanata is a keyboard remapper that allows you to:
- Remap any key to any other key
- Create layers (similar to vim modes) for different key behaviors
- Implement tap-hold functionality (different actions for tap vs hold)
- Create macros and combos
- Improve ergonomics without hardware changes

**Key Features:**
- Cross-platform (macOS, Linux, Windows)
- Low latency
- Powerful configuration language
- Active development and community

## 🚀 Installation on macOS (Tahoe)

### Prerequisites

1. **Nix Package Manager** (should already be installed if using this dotfiles repo)
2. **macOS Permissions** for Accessibility and Input Monitoring

### Installation Steps

Kanata is already included in the Nix Darwin configuration, so it will be installed automatically when you apply the system configuration.

#### Option 1: Using Nix Darwin (Recommended)

If you haven't already applied the Nix Darwin configuration:

```bash
cd ~/.dotfiles
darwin-rebuild switch --flake .#macmini  # or .#macbook for Intel Mac
```

#### Option 2: Verify Installation

Check if Kanata is installed:

```bash
which kanata
kanata --version
```

### macOS Permissions Setup

Kanata requires accessibility permissions to function:

1. **System Settings** → **Privacy & Security** → **Accessibility**
2. Click the lock icon to make changes
3. Add the terminal application you'll run Kanata from (e.g., Kitty, iTerm2, Terminal)
4. Also add `/usr/bin/kanata` if it appears

For Input Monitoring:
1. **System Settings** → **Privacy & Security** → **Input Monitoring**
2. Add your terminal application

**Note:** You may need to restart your terminal after granting permissions.

## ⚙️ Configuration

The main configuration file is located at:
```
~/.dotfiles/kanata/kanata.kbd
```

### Configuration File Structure

```lisp
;; Source - Define your keyboard layout
(defsrc ...)

;; Layers - Define different keyboard behaviors
(deflayer default ...)
(deflayer navigation ...)

;; Aliases - Define tap-hold and other complex behaviors
(defalias
  cap (tap-hold 200 200 esc lctl)
)

;; Config - Global settings
(defcfg ...)
```

### Default Configuration

The provided `kanata.kbd` includes:

1. **Function Key Mappings**
   - F1/F2: Brightness down/up
   - F3: Launchpad
   - F4: Mission Control
   - F5/F6: Keyboard backlight down/up
   - F7-F9: Media controls (previous, play/pause, next)
   - F10-F12: Mute, volume down/up

2. **Caps Lock Enhancement**
   - **Tap**: Escape key
   - **Hold**: Control key

3. **Navigation Layer** (accessed via Caps Lock + other keys)
   - `Caps + H/J/K/L`: Arrow keys (left/down/up/right)
   - `Caps + Y/U/I/O`: Home/PgDn/PgUp/End

## 🎮 Usage

### Starting Kanata

#### Method 1: Manual Start

```bash
# Start with config file
kanata -c ~/.dotfiles/kanata/kanata.kbd
```

#### Method 2: Background Service (Recommended for daily use)

Create a launch agent for automatic startup:

```bash
# Create the launch agent directory if it doesn't exist
mkdir -p ~/Library/LaunchAgents

# Create a launch agent plist
cat > ~/Library/LaunchAgents/com.kanata.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.kanata</string>
    <key>ProgramArguments</key>
    <array>
        <string>/nix/store/$(readlink /nix/var/nix/profiles/system/sw/bin/kanata | sed 's|/bin/kanata||')/bin/kanata</string>
        <string>-c</string>
        <string>$HOME/.dotfiles/kanata/kanata.kbd</string>
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
EOF

# Load the launch agent
launchctl load ~/Library/LaunchAgents/com.kanata.plist

# Check if it's running
launchctl list | grep kanata
```

#### Method 3: Start on Terminal Launch

Add to your `~/.zshrc` or shell config:

```bash
# Start kanata in background if not already running
if ! pgrep -x "kanata" > /dev/null; then
    kanata -c ~/.dotfiles/kanata/kanata.kbd > /tmp/kanata.log 2>&1 &
fi
```

### Stopping Kanata

```bash
# If started manually
pkill kanata

# If using launch agent
launchctl unload ~/Library/LaunchAgents/com.kanata.plist
```

### Reloading Configuration

After editing `kanata.kbd`:

```bash
# Kill and restart
pkill kanata
kanata -c ~/.dotfiles/kanata/kanata.kbd &
```

## 💡 Common Use Cases

### 1. Caps Lock as Escape/Control

**Use Case:** Make Caps Lock more useful
- Tap for Escape (great for Vim users)
- Hold for Control (ergonomic for keyboard shortcuts)

**Already configured** in the default `kanata.kbd`:
```lisp
(defalias
  cap (tap-hold 200 200 esc lctl)
)
```

### 2. Home Row Navigation

**Use Case:** Navigate without moving hands from home row

Using Caps Lock + H/J/K/L for arrow keys:
```lisp
;; In navigation layer
h -> left
j -> down  
k -> up
l -> right
```

### 3. Custom Macros

**Example:** Create a macro for typing your email

Add to your config:
```lisp
(defalias
  email (macro y o u r e m a i l @ e x a m p l e . c o m)
)

;; Then bind to a key in a layer
(deflayer default
  ... @email ...
)
```

### 4. Application Launcher Layer

**Example:** Quick launch apps with a modifier

```lisp
(defalias
  apps (layer-while-held apps)
)

(deflayer apps
  _    _    _    _    _    _    _    _    _    _    _    _    _
  _    _    _    _    _    _    _    _    _    _    _    _    _    _
  _    _    _    @eml _    @trm _    _    _    _    _    _    _    _
  _    _    _    _    _    _    _    _    _    _    _    _    _
  _    _    _    @cod _    @brs _    _    _    _    _    _
  _    _    _    _              _              _    _
)

(defalias
  eml (cmd open -a Mail.app)
  trm (cmd open -a Kitty.app)
  cod (cmd open -a "Visual Studio Code.app")
  brs (cmd open -a "Safari.app")
)
```

### 5. Vim-Style Window Management

**Example:** Quick window snapping with a modifier

```lisp
;; Hold Space for window management layer
(defalias
  win (layer-while-held window)
)

(deflayer window
  _    _    _    _    _    _    _    _    _    _    _    _    _
  _    _    _    _    _    _    _    _    _    _    _    _    _    _
  _    _    _    _    _    _    _    _    _    _    _    _    _    _
  _    _    _    _    @fll _    @hlf _    _    @lft _    _    _
  _    _    _    _    _    _    _    @mid _    _    @rgt _
  _    _    _    _              _              _    _
)

;; Requires Rectangle or similar app with keyboard shortcuts
(defalias
  fll (cmd lctl lalt ret)     ;; Fullscreen
  hlf (cmd lctl lalt rght)    ;; Half right
  lft (cmd lctl lalt left)    ;; Left half
  rgt (cmd lctl lalt rght)    ;; Right half
  mid (cmd lctl lalt c)       ;; Center
)
```

## 🔧 Troubleshooting

### Kanata Not Starting

**Issue:** Kanata fails to start or permission denied

**Solution:**
1. Check accessibility permissions (see [macOS Permissions Setup](#macos-permissions-setup))
2. Ensure config file syntax is correct: `kanata -c ~/.dotfiles/kanata/kanata.kbd --check`
3. Check logs: `tail -f /tmp/kanata.log`

### Keys Not Remapping

**Issue:** Configuration loaded but keys don't remap

**Solutions:**
1. Verify Kanata is running: `ps aux | grep kanata`
2. Check config syntax: `kanata -c ~/.dotfiles/kanata/kanata.kbd --check`
3. Restart Kanata: `pkill kanata && kanata -c ~/.dotfiles/kanata/kanata.kbd &`
4. Check for conflicting software (Karabiner-Elements, BetterTouchTool)

### Config Validation

Test your config before applying:

```bash
kanata -c ~/.dotfiles/kanata/kanata.kbd --check
```

### High CPU Usage

**Issue:** Kanata using significant CPU

**Solutions:**
1. Check for infinite loops in your config
2. Reduce logging level
3. Update to latest version: `nix flake update && darwin-rebuild switch --flake .#macmini`

### Conflicts with Other Tools

If you're using other keyboard tools:
- **Karabiner-Elements**: May conflict, choose one
- **BetterTouchTool**: Can coexist but test thoroughly
- **Hammerspoon**: Can coexist

### Debugging

Enable debug logging:

```bash
# Run with verbose output
kanata -c ~/.dotfiles/kanata/kanata.kbd -d
```

Check logs:
```bash
tail -f /tmp/kanata.log
tail -f /tmp/kanata.err
```

## 📖 Advanced Configuration

### Multi-layer Setup

Create multiple layers for different contexts:

```lisp
;; Symbol layer for easy access to symbols
(deflayer symbols
  _    _    _    _    _    _    _    _    _    _    _    _    _
  _    !    @    #    $    %    ^    &    *    \(   \)   _    _    _
  _    _    _    _    _    _    _    _    _    _    _    _    _    _
  _    _    _    _    _    _    _    _    _    _    _    _    _
  _    _    _    _    _    _    _    _    _    _    _    _
  _    _    _    _              _              _    _
)
```

### Chords

Execute actions when multiple keys are pressed together:

```lisp
(defchords name 200
  (j k) esc
  (s d) (layer-while-held navigation)
)
```

### Tap-Dance

Different actions based on tap count:

```lisp
(defalias
  td (tap-dance 200 (a b c))
)
;; Tap once = 'a', twice = 'b', three times = 'c'
```

## 🎓 Learning Resources

### Official Documentation
- [Kanata GitHub Repository](https://github.com/jtroo/kanata)
- [Kanata Configuration Guide](https://github.com/jtroo/kanata/blob/main/docs/config.adoc)
- [Example Configurations](https://github.com/jtroo/kanata/tree/main/cfg_samples)

### Community
- [GitHub Discussions](https://github.com/jtroo/kanata/discussions)
- [GitHub Issues](https://github.com/jtroo/kanata/issues)

### Related Tools
- [QMK Firmware](https://qmk.fm/) - Hardware-based alternative
- [Karabiner-Elements](https://karabiner-elements.pqrs.org/) - macOS-specific alternative
- [kmonad](https://github.com/kmonad/kmonad) - Similar cross-platform tool

## 📝 Configuration Tips

1. **Start Simple**: Begin with basic remappings, add complexity gradually
2. **Test Thoroughly**: Test each change before adding more
3. **Use Comments**: Document your config for future reference
4. **Back Up**: Keep your config in version control (already done in this repo!)
5. **Iterate**: Adjust timings (tap-hold delays) to match your typing style

## 🔐 Security Considerations

- Kanata requires accessibility permissions (full keyboard access)
- Only use trusted configuration files
- Review config changes carefully
- Keep Kanata updated via Nix: `nix flake update`

## 🚀 Next Steps

After installation:

1. **Test the default config**: Start Kanata and test Caps Lock behavior
2. **Customize for your needs**: Edit `kanata.kbd` to match your workflow
3. **Set up autostart**: Use the launch agent method for daily use
4. **Explore examples**: Check the [official examples](https://github.com/jtroo/kanata/tree/main/cfg_samples)

## 📋 Quick Reference Card

| Key Combo | Action |
|-----------|--------|
| `Caps (tap)` | Escape |
| `Caps (hold)` | Control |
| `Caps + H/J/K/L` | Arrow keys (left/down/up/right) |
| `Caps + Y/U/I/O` | Home/PgDn/PgUp/End |
| `F1/F2` | Brightness |
| `F7/F8/F9` | Media controls |
| `F10/F11/F12` | Volume |

---

**Note:** This configuration is optimized for macOS (Tahoe machine) and integrates with the Nix Darwin dotfiles setup. Configuration changes are tracked in git, making it easy to sync across machines or rollback changes.
