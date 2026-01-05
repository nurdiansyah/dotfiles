# home/ — user-scoped configuration files

This directory contains top-level Home Manager configuration files for the user.

Starship prompt configuration
- `starship.toml` (this file) is used as the source of truth for Starship.
- It is symlinked/deployed to `~/.config/starship.toml` by `home/home.nix`:

  home.file.".config/starship.toml".text = builtins.readFile ./starship.toml;

Why move it to `home/`?
- Keeps all user-level Home Manager configuration files discoverable in one place.
- Easier to find and edit when using `nix` + `home-manager` workflows.

If you prefer the previous location `home/zsh/starship.toml`, you can move it back and update `home/home.nix` accordingly.