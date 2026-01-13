# Migration Guide: From Nix/Home Manager → Homebrew-first (short)

This repository previously documented migration to Nix/darwin. Nix/Home Manager support is no longer maintained here; follow these steps to move to a Homebrew-first workflow.

## 🔧 Quick migration steps

1. Backup your Nix state & dotfiles:
   - `nix profile list` (or `nix-env -q`) to list user packages
   - Archive `/nix` if you want to keep it: `sudo mv /nix /nix-backup-$(date +%Y%m%d)`
   - Backup `~/.config/home-manager` and your dotfiles

2. Install Brew packages from this repo's `Brewfile`:
   ```bash
   brew bundle --file=Brewfile
   ```

3. Restore or migrate user-level packages and tools to Homebrew/npm/pip/pnpm as appropriate.

4. Restore repo-managed dotfiles (copy or source `./.zshrc`):
   ```bash
   cp ~/dotfiles/.zshrc ~/.zshrc
   source ~/.zshrc
   ```

5. Clean up Nix remnants (if not done already):
   - Unload and remove Nix plists and services
   - Remove `/nix` only after you have backups and confirmed nothing needs it

## Notes
- This file replaces the prior long Nix-focused migration guide. If you need the previous instructions, look in the git history or in archived PRs. If you need help migrating specific packages, I can extract common mappings (e.g., `fzf`, `direnv`, `starship`) into the `Brewfile` for you.

## Checklist (Homebrew migration)
- [ ] Backup Nix state
- [ ] Run `brew bundle --file=Brewfile`
- [ ] Migrate any remaining tools to appropriate package managers
- [ ] Remove `/nix` after backups and verification


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
1. Check the bootstrap or install script output for error messages (e.g., `./install.sh`)
2. Review relevant package docs (Homebrew or upstream project docs)
3. Try rollback using git or restore backups (e.g., revert changes in the repo / restore backup directories)
4. Ask in the project/community channels for the specific tool you're using (Homebrew, package project, etc.)

## 🔐 Security Notes

- Nix keeps older generations for safety
- Flake.lock prevents supply chain attacks via pinned versions
- **Secrets:** Do NOT commit tokens/credentials to the repo. Store secrets in the macOS Keychain, environment variables, or a local file like `~/.zsh_local` (which must be gitignored). Consider using tools like `pass`, `1password`, or `secret-service` integrations.
- All configs are plaintext and reviewable
