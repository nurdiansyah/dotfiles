{ config, pkgs, machineType, ... }:

# Machine-specific configurations
let
  configs = {
    # MacBook Air/Pro configuration (Intel)
    macbook = {
      # Intel-specific packages and settings
      environment.systemPackages = with pkgs; [
        # Laptop-specific tools
        tlp  # Power management for Intel
        powertop  # Power analysis
      ];
      
      system.defaults.trackpad = {
        Clicking = true;
        Dragging = true;
        TrackpadThreeFingerDrag = true;
      };
      
      # Optimize for Intel processor
      nix.settings.max-jobs = 4;
      nix.settings.cores = 0;  # Use all cores
    };
    
    # Mac Mini configuration (Apple Silicon M4)
    macmini = {
      # ARM64-specific packages and settings
      environment.systemPackages = with pkgs; [
        # Desktop-specific tools
        # M4 runs most tools natively or through Rosetta
      ];
      
      # More aggressive caching for Apple Silicon
      nix.settings.max-jobs = 8;
      nix.settings.cores = 0;
      
      # Apple Silicon specific
      nix.settings.extra-platforms = [
        "aarch64-darwin"
        "x86_64-darwin"  # Support Rosetta fallback
      ];
    };
  };
in

configs.${machineType} or {}
