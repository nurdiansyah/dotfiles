Title: chore: remove Nix support and archive artifacts

Summary
-------
This PR archives Nix-related configuration and tooling from the repository and updates shell configs and documentation to use Homebrew-first workflows.

Why
---
- Nix/darwin usage is being removed from active maintenance and support in this repo.
- Preserve historical Nix artifacts for potential rollback by archiving them in `archive/nix/`.
- Prevent user breakage by guarding shell references to `/nix` and Home Manager-managed files.

What changed
------------
- Archived Nix artifacts: `darwin/`, `flake.nix`, `flake.lock`, `NIX_DARWIN.md`, `install-nix.sh`, `.config/home-manager/` → `archive/nix/` (moved with git history preserved).
- Guarded `/nix` references in `/.zshrc` to avoid errors when `/nix` is absent.
- Updated `zsh/.zshrc` alias `zshconfig` to point to repo-managed `~/.zshrc` instead of Home Manager.
- Added `NIX_UNINSTALL.md` with safe removal instructions.
- Updated `Brewfile`, `README.md`, and `MACHINES.md` to reflect Nix archiving and migration to Homebrew.

Testing
-------
- Reviewers: verify that `./install.sh` and `Brewfile` install the packages you need without Nix.
- Manually source `~/.zshrc` (or open a new shell) to ensure no errors are produced when `/nix` is absent.
- Confirm the archived directory `archive/nix/` contains the expected files and documentation.

Rollback
--------
To rollback:
1. Checkout the archived branch or revert this PR.
2. Move files back from `archive/nix/` to their original paths and commit.
3. Restore any Home Manager-managed dotfiles from `.before-nix-darwin` backups or git history.

Checklist
--------
- [x] Archive Nix artifacts in `archive/nix/` with git history preserved
- [x] Guard `/nix` references in shell startup files
- [x] Update `Brewfile` and docs to reflect migration
- [x] Add `NIX_UNINSTALL.md` with safe, step-by-step uninstall instructions
- [x] Add PR description and testing notes

Notes
-----
This PR intentionally does not delete the system `/nix` directory. Deleting `/nix` is irreversible and should be done manually by the user after they have taken adequate backups and verified there are no Nix processes/services running.
