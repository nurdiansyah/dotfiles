# Kanata Quick Start Guide

Quick reference for getting started with Kanata on macOS (Tahoe).

## ⚠️ Before You Start

**IMPORTANT:** Kanata on macOS requires:
1. **Karabiner VirtualHIDDevice driver v6.2.0** - Download from: https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases
2. **sudo/root access** - Kanata must be run with `sudo` on macOS

If you haven't installed the driver yet, see [INSTALL-MACOS.md](INSTALL-MACOS.md) for full instructions.

## 🚀 Quick Start (5 minutes)

### 1. Start Kanata

```bash
# Run with sudo (required on macOS)
sudo kanata -c ~/.dotfiles/kanata/kanata.kbd
```

Enter your password when prompted. Leave this terminal window open. Kanata is now active!

### 2. Test Your Configuration

Try these to verify it's working:

| Test | Expected Result |
|------|----------------|
| Tap Caps Lock | Should act as Escape |
| Hold Caps Lock, press H | Should move cursor left (arrow left) |
| Hold Caps Lock, press J | Should move cursor down (arrow down) |
| Hold Caps Lock, press K | Should move cursor up (arrow up) |
| Hold Caps Lock, press L | Should move cursor right (arrow right) |

### 3. If Something Goes Wrong

**Can't type normally?**
- Press `Ctrl+C` in the terminal window where Kanata is running
- This stops Kanata and returns keyboard to normal

**Keys not remapping?**
- Did you install the Karabiner VirtualHIDDevice driver?
- Are you running with `sudo`?
- Check System Settings → Privacy & Security → Accessibility
- Ensure your terminal app (Kitty, iTerm2, etc.) is in the list

## 📖 Basic Concepts

### Layers

Think of layers like Shift key - pressing Shift changes what other keys do.
Kanata lets you create custom layers.

**Example:** Caps Lock is a layer key in the default config.
- Hold Caps Lock → Enter "navigation" layer
- Now H/J/K/L become arrow keys
- Release Caps Lock → Return to normal typing

### Tap vs Hold

Keys can do different things when tapped vs held.

**Example:** Caps Lock (in default config)
- **Tap** quickly → Escape key
- **Hold** → Control modifier
- **Hold** + other keys → Navigation layer

### Aliases

Shortcuts for complex behaviors. Defined with `(defalias ...)`.

**Example:**
```lisp
(defalias
  cap (tap-hold 200 200 esc lctl)
)
```
This means: "Create an alias called 'cap' that sends Escape on tap, Control on hold"

## 🎯 Default Configuration Summary

Your default `kanata.kbd` includes:

### Function Keys
- F1/F2: Brightness
- F3: Launchpad
- F4: Mission Control
- F7/F8/F9: Media controls
- F10/F11/F12: Volume

### Caps Lock
- Tap: Escape
- Hold: Control
- Hold + H/J/K/L: Arrow keys
- Hold + Y/U/I/O: Home/PgDn/PgUp/End

## 🛠️ Common Customizations

### Change Tap-Hold Timing

If Caps Lock is too sensitive (triggering wrong action):

```lisp
;; In kanata.kbd, find this line:
(defalias
  cap (tap-hold 200 200 esc lctl)
)

;; Increase the numbers (in milliseconds):
(defalias
  cap (tap-hold 300 300 esc lctl)
)
```

### Add Another Tap-Hold Key

Want Tab to work like Caps Lock?

```lisp
;; 1. Add alias
(defalias
  tab-esc (tap-hold 200 200 tab lctl)
)

;; 2. Use it in your layer
(deflayer default
  ... @tab-esc ...
)
```

### Remap a Single Key

Want to swap two keys?

```lisp
;; In (deflayer default ...)
;; Find the key position and change it

;; Example: Swap Escape and Grave (`)
(deflayer default
  grv  ... ;; Put grv where esc was
  esc  ... ;; Put esc where grv was
  ...
)
```

## 🔍 File Locations

```
~/.dotfiles/kanata/
├── kanata.kbd      # Main config (edit this)
├── examples.kbd    # Advanced examples (reference only)
└── README.md       # Full documentation
```

## 📝 Editing Your Config

1. Open the config file:
   ```bash
   # Use your preferred editor (nvim, vim, nano, etc.)
   nvim ~/.dotfiles/kanata/kanata.kbd
   ```

2. Make your changes

3. Save the file

4. Reload Kanata:
   ```bash
   # In the terminal where Kanata is running, press Ctrl+C
   # Then restart it with sudo:
   sudo kanata -c ~/.dotfiles/kanata/kanata.kbd
   ```

## 🆘 Emergency: Disable Kanata

If something goes very wrong and you can't type:

1. **Force quit the terminal** running Kanata
2. Or run `sudo pkill kanata` from another terminal
3. Or restart your computer (keyboard will work normally on reboot)

## ✅ Setup for Daily Use

Once you're happy with your config, make Kanata start automatically:

### Option 1: LaunchDaemon (Recommended)

See [INSTALL-MACOS.md](INSTALL-MACOS.md) for LaunchDaemon setup (runs Kanata with sudo at boot).

### Option 2: Add to Terminal Startup (Not Recommended)

This requires entering password on every terminal launch:
```bash
# Add to ~/.zshrc
if ! pgrep -x "kanata" > /dev/null; then
    sudo kanata -c ~/.dotfiles/kanata/kanata.kbd > /tmp/kanata.log 2>&1 &
fi
```

## 🎓 Next Steps

1. **Use it for a day** - Get comfortable with the defaults
2. **Read README.md** - Explore more features
3. **Check examples.kbd** - See advanced configurations
4. **Customize** - Add your own remappings
5. **Share** - Your changes are in git, easy to sync!

## 💡 Tips

- **Start simple** - Don't change too much at once
- **Test changes** - Verify each change before adding more
- **Keep backups** - Git tracks your configs (already done!)
- **Adjust timing** - Everyone types differently, tune tap-hold delays
- **Use layers** - Better than complex modifier combinations

## 🔗 Quick Links

- [Full Documentation](README.md)
- [Advanced Examples](examples.kbd)
- [Kanata GitHub](https://github.com/jtroo/kanata)
- [Kanata Config Guide](https://github.com/jtroo/kanata/blob/main/docs/config.adoc)

---

**Remember:** You can always stop Kanata with `Ctrl+C` in its terminal window!
