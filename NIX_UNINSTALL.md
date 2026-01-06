# Uninstalling Nix (safe removal guide)

WARNING: Removing `/nix` is destructive and irreversible. Back up any data you may need and ensure you can restore from git before proceeding.

1. Backup
   - Export lists of installed packages (e.g., `nix profile list` or `nix-env -q`).
   - Make a copy of `/nix` if you want to archive it: `sudo mv /nix /nix-backup-$(date +%Y%m%d)`.
   - Backup this repository and the `darwin/` and `home/` configs (already archived in `archive/nix/`).

2. Stop Nix services
   - Check for Nix daemons/agents: `launchctl list | grep -i nix`.
   - Unload any Nix plists: `sudo launchctl bootout system /Library/LaunchDaemons/org.nixos.nix-daemon.plist` (example).
   - Archive the plists (optional, recommended): after unloading, move the plists to a safe location so they won't be accidentally reloaded:
     ```bash
     sudo mkdir -p /Library/LaunchDaemons/archived-nix
     sudo mv /Library/LaunchDaemons/org.nixos.* /Library/LaunchDaemons/archived-nix/
     ls -la /Library/LaunchDaemons/archived-nix
     ```
     This preserves the files if you want to restore them later; remove them permanently only after you are sure you will delete `/nix`.

3. Restore dotfiles
   - Restore files from `.before-nix-darwin` or from git if Home Manager replaced them.
   - Remove Home Manager runtime files: `rm -rf ~/.config/home-manager` (after backups).

4. Remove Nix configuration
   - Remove flakes config: `rm -f ~/.config/nix/nix.conf` or edit it to remove `experimental-features = nix-command flakes`.

5. Remove the Nix store (destructive)
   - Ensure no Nix processes run and services are stopped.
   - Remove `/nix` to reclaim space: `sudo rm -rf /nix` OR keep it archived as a backup.

6. Clean shell startup files
   - Remove or guard any `/nix` references in `~/.zshrc`, `~/.zprofile`, etc. (this repo has guarded references now).

7. Repo cleanup
   - The repo has archived nix artifacts in `archive/nix/`. Review `Brewfile` to ensure replacement packages are present and run `brew bundle` to install them.

If you want, follow the steps above manually or ask me to generate a safe, commented script that performs non-destructive checks and prompts before any destructive action.
