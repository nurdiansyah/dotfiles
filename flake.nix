{
  description = "Nurdiansyah's macOS & Home Configuration (Nix Darwin + Home Manager)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, darwin, home-manager, nixpkgs }:
    let
      username = "nurdiansyah";
      
      # Machine configurations with architecture
      machines = {
        macbook = {
          hostname = "nurdiansyah-macbook";
          computerName = "Nurdiansyah's MacBook";
          localHostName = "nurdiansyah-mbp";
          system = "x86_64-darwin";  # Intel
        };
        macmini = {
          hostname = "nurdiansyah-macmini";
          computerName = "Nurdiansyah's MacMini";
          localHostName = "nurdiansyah-mini";
          system = "aarch64-darwin";  # Apple Silicon M4
        };
      };
      
      # Create darwin configuration for a machine
      mkDarwinConfig = machineType: machine:
        let
          system = machine.system;
          pkgs = nixpkgs.legacyPackages.${system};
        in
        darwin.lib.darwinSystem {
          inherit system;
          modules = [
            { _module.args = { inherit machineType pkgs; }; }
            ./darwin/configuration.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${username} = import ./home/home.nix {
                inherit pkgs username machineType;
              };
            }
          ];
          specialArgs = {
            inherit machine machineType;
          };
        };
    in
    {
      # Create configurations for each machine
      darwinConfigurations = let dc = builtins.mapAttrs mkDarwinConfig machines; in dc // { default = dc.macmini; };

      # Formatters for both architectures
      formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixpkgs-fmt;
      formatter.x86_64-darwin = nixpkgs.legacyPackages.x86_64-darwin.nixpkgs-fmt;
    };
}
