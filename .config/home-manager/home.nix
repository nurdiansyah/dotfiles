# Wrapper for local Home Manager usage
# - Imports the repo's `home/home.nix` module with the required args
# - Using a relative path keeps this file portable for contributors/CI
#
# Note: This wrapper imports files from the local working tree which requires
# impure evaluation. To apply locally run:
#   nix run github:nix-community/home-manager#home-manager -- switch --impure
# Prefer using a flake-based invocation (e.g., `home-manager switch --flake .`)
# in CI or for reproducible/pure evaluation once the flake is published.
{ pkgs, ... }:

let
  repoHome = import ../../home/home.nix {
    inherit pkgs;
    username = "nurdiansyah";
    # optional: machineType = "macmini";
  };
in
{
  imports = [ repoHome ];

  # These are local defaults; the imported module will also set them.
  home.username = "nurdiansyah";
  home.homeDirectory = "/Users/nurdiansyah";
}
