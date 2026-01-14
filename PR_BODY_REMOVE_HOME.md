Title: chore: remove `home/` module (Home Manager) and update docs

Summary
-------
This PR removes the `home/` module (Home Manager configuration) from the repository and updates documentation to remove Home Manager-specific workflow references.

Why
---
- The repository is moving to a Homebrew-first workflow and no longer maintains Home Manager/Nix-based user configuration.
- Removing the `home/` module avoids confusion and reduces maintenance burden.

What changed
------------
- Deleted: `home/home.nix`, `home/README.md`.
- Updated: `zsh/README.md` to reference the consolidated `./.zshrc` and to remove references to `home/zsh`.
- Updated: `.github/copilot-instructions.md` to remove active Home Manager usage and mark it as previously supported.

Testing
-------
- Verify local `zsh` setup uses `~/.zshrc` from the repo and no `home/` paths remain in docs.
- Confirm `install.sh` and `Brewfile` work as expected without attempting to run Nix or Home Manager.

Rollback
--------
To rollback: restore `home/` from git history or revert this PR.

Checklist
--------
- [x] Remove `home/` module files
- [x] Update docs referencing `home/` and Home Manager
- [ ] Add tests or verification steps if required (not necessary for docs-only change)
