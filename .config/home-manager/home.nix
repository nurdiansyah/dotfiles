{ pkgs, ... }:

let
  repoHome = import /Users/nurdiansyah/dotfiles/home/home.nix {
    inherit pkgs;
    username = "nurdiansyah";
    # optional: machineType = "macmini";
  };
in
{
  imports = [ repoHome ];

  home.username = "nurdiansyah";
  home.homeDirectory = "/Users/nurdiansyah";
}
