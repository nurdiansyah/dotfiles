npm installer

This folder contains a manifest and an idempotent installer for global npm/pnpm/yarn CLIs used by the dotfiles.

Files
- `npm-globals.txt` — manifest (one package per line). Use `package@version` to pin.
- `install-npm-globals.sh` — implementation. Supports `--manager=auto|npm|pnpm|yarn`, `--dry-run`, `--yes`.
- `install.sh` — thin wrapper that delegates to `install-npm-globals.sh`.

Usage examples
- Dry-run with auto manager detection:
  bash npm/install.sh --dry-run
- Install with pnpm and assume yes:
  bash npm/install.sh --manager=pnpm --yes

Notes
- The script uses `NPM_HOME` (default `~/.npm-packages`) and `PNPM_HOME` (default `~/.pnpm`) so installs avoid `sudo` by default.
- Ensure the appropriate bin dirs are in your PATH (e.g., `$NPM_HOME/bin`, `$PNPM_HOME/bin`).
