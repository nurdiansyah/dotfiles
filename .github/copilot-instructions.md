# GitHub Copilot / Agent Instructions — dotfiles

Short summary
- This is a personal dotfiles repository for macOS development (Neovim, zsh, tmux, Kanata, package manifests). Treat changes as user-facing environment changes — prefer safe, small edits and PRs for config updates.

High-level architecture (what matters)
- Top-level components: `nvim/` (profile-based Neovim), `zsh/`, `tmux/`, `kanata/`, `Brewfile` and `scripts/` (installer helpers), `npm/` (manifest + installer).
- Primary workflow: "dotfiles" standalone (copy/symlink files, run `install.sh`). Nix/Home Manager was previously supported but is no longer maintained in this repo.

When you start
- Read `README.md` (root) and module READMEs (`nvim/README.md`, `kanata/INSTALL-MACOS.md`, `npm/README.md`).
- Use `./install.sh --help` to see supported flags (`--brewfile`, `--hererocks`, `--npm-globals`, `--update-brewfile`, `--commit-brewfile`).

Important conventions & examples (actionable)
- Brewfile edits: prefer `./install.sh --update-brewfile` which creates a backup `Brewfile.bak.<UTC timestamp>`; automated commit message format used by the script is `chore(brewfile): add <pkg1> <pkg2>`. If adding packages manually, create a branch and open a PR for review.
- Neovim profiles: add a profile at `nvim/lua/plugins/profiles/<name>.lua`. Wire detection in `nvim/lua/utils/root.lua` (e.g. check for `package.json`, `charts/` or custom files). Update `nvim/lua/core/statusline.lua` if you add profile icons.
  - To test: `NVIM_PROFILE=<name> nvim`, inside Neovim run `:Lazy sync`, `:checkhealth`, `:TSUpdate`, and verify `:Mason` / `:checkhealth` for LSP issues.
- NPM globals: manifest is `npm/npm-globals.txt`; installer is `npm/install-npm-globals.sh` (supports `--manager`, `--dry-run`, `--yes`). Use `npm/install.sh --dry-run` first.
- Scripts: scripts live under `scripts/`. Keep them executable and add a small `--help`/usage block. Use `bash -n` for quick syntax checks and include a smoke test (`scripts/test_bootstrap.sh` demonstrates expectations for `bootstrap_hererocks.sh`).
- (Legacy) Nix/Home Manager configuration is no longer maintained in this repository.
- Kanata (keyboard remapper): macOS requires Karabiner VirtualHIDDevice driver v6.2.0 (see `kanata/INSTALL-MACOS.md`). Validate configs with `kanata -c ~/.config/kanata/kanata.kbd --check` (or fallback to `~/dotfiles/kanata/kanata.kbd`) and run manually with `sudo kanata -c ...` for initial tests.

Testing & verification
- Unit-like smoke-tests exist as small shell checks (e.g., `scripts/test_bootstrap.sh`). Use these as templates for new script tests.
- Neovim verification is manual: `nvim` then `:checkhealth`, `:Lazy sync`, `:TSUpdate`.
- No CI workflows are present in this repo—ask maintainers before adding heavy CI.

Style & safety rules for agents (do not assume anything)
- Do not modify `Brewfile` and commit automatically without the `--update-brewfile --commit-brewfile` flow or an explicit PR. The installer creates backups — preserve them.
- Avoid changing system-level config without confirming the target machine (darwin flakes reference machines like `#macmini` or `#macbook`).
- For changes that affect runtime behavior (keyboard, shell, LSPs), include clear 'how to test' steps and at least one smoke command (e.g., `kanata --check`, `:checkhealth` in nvim, `bash -n scripts/...`).

Files to reference when making edits (quick map)
- repo README: `README.md`
- installer: `install.sh`, `scripts/bootstrap_hererocks.sh`, `npm/install-npm-globals.sh`
- Neovim: `nvim/` — detection: `nvim/lua/utils/root.lua`, profiles: `nvim/lua/plugins/profiles/`, keymaps: `nvim/lua/core/keymaps.lua`
- Nix artifacts referenced historically: `archive/nix/`, `MACHINES.md`, `NIX_DARWIN.md`
- Kanata: `kanata/kanata.kbd`, `kanata/INSTALL-MACOS.md`

If something is unclear
- Ask for clarification and link to the file you intend to change (e.g., "I want to add tool X to the Brewfile; do you want it appended automatically or added via a PR?").

Thanks — please review and tell me if you want more detail or example PR templates for common change types.
