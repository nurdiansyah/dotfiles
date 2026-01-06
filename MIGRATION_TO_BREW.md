# Migration: Nix → Homebrew (draft)

This document describes the minimal steps to migrate package management from Nix to Homebrew for this dotfiles repo.

1. Review `Brewfile` (draft) in the `migration/nix-to-brew` branch. Items marked TODO need verification.
2. Install Homebrew (if not installed):
   - /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
3. Install packages from Brewfile (recommended):
   - brew bundle --file=Brewfile
   - OR run the repo installer which will apply the Brewfile and prompt to install npm globals:
     - chmod +x install.sh && ./install.sh --brewfile
4. Install npm-based language servers globally where noted (e.g., `npm i -g typescript-language-server typescript`).
   - The `--brewfile` installer will prompt to install these automatically if `npm` is available.

5. Install zsh plugins via your preferred plugin manager or clone them to `~/.zsh`.
6. Test tooling (neovim, kubectl, rust-analyzer, etc.).
7. Once verified, update repository docs and remove corresponding Nix declarations from `darwin/configuration.nix` and `home/home.nix` (create separate PR for removal to keep changes reviewable).
8. Optional: run `sudo nix-collect-garbage -d` after ensuring no needed paths are in use.

Notes:
- Keep the `backup/nix-before-manual-YYYY-MM-DD` branch and tag as a restore point.
- This migration intentionally splits verification (install and test) from removal of Nix entries to minimize risk.
