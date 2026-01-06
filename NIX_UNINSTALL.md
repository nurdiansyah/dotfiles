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


---

## Deletion status (actions taken on 2026-01-06)

- The Nix APFS volume **"Nix Store"** (device `disk3s7`) was unmounted and removed from the APFS container using `diskutil apfs deleteVolume` on **2026-01-06**.
- A small metadata bundle and logs were saved to `/var/tmp` with timestamp **20260106_184517**:
  - `/var/tmp/nix-size-20260106_184517.txt` (du -sh)
  - `/var/tmp/nix-ls-20260106_184517.txt` (ls -la)
  - `/var/tmp/nix-sample-20260106_184517.txt` (sample listing)
  - `/var/tmp/nix-var-nix-20260106_184517.tar.gz` (archive of `/nix/var/nix`)
  - `/var/tmp/nix-delete-meta-20260106_184517.txt` (delete metadata)

**Note:** the Nix APFS volume was removed and the bulk of the store data is gone. However, an empty mountpoint directory `/nix` remains and could not be removed from the running system (`rmdir` failed with "Read-only file system"). This is a benign leftover directory but if you want it removed entirely you may need to:

1. Reboot into Recovery (or single-user) and remove it there, or
2. Temporarily disable protections that prevent deleting root-level directories (advanced; proceed with caution), or
3. Keep it as an empty placeholder — it is harmless but empty.

If you'd like, I can prepare a short Recovery-mode removal guide or attempt the removal with you (I will not attempt further destructive steps without your explicit OK).
