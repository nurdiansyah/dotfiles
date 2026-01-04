{ config, pkgs, machine, machineType, ... }:

{
  # System configuration for macOS
  system.stateVersion = 5;
  system.primaryUser = "nurdiansyah";
  
  # ============================================================================
  # Hostname Configuration (machine-specific)
  # ============================================================================
  networking.hostName = machine.hostname;
  networking.computerName = machine.computerName;
  networking.localHostName = machine.localHostName;

  # ============================================================================
  # System Packages
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # Core tools
    coreutils
    curl
    wget
    git
    gnupg
    openssh
    
    # Development
    neovim
    zsh
    
    # Build tools
    gcc
    cmake
    pkg-config
    
    # Command-line utilities
    fd
    ripgrep
    tree-sitter
    jq
    yq
    fzf
    
    # Python
    python311
    python311Packages.pip
    
    # Kubernetes & DevOps
    kubectl
    kubernetes-helm
    
    # Other tools
    btop
    bat
    delta

    # Moved from Homebrew brews -> manage via Nix for reproducibility
    bash
    pkgs.bashInteractive
    pkgs."bash-completion"
    direnv
    eza
    fastfetch
    gh
    git-lfs
    k9s
    kanata
    mcfly
    nushell
    sketchybar
    starship
    stow
    watchman
    zoxide
    zsh-autosuggestions
  ];

  # Machine-specific configuration
  imports = [ ./machines.nix ];

  # ============================================================================
  # Nix Configuration
  # ============================================================================
  nix.settings = {
    # Enable flakes
    experimental-features = [ "nix-command" "flakes" ];
  };

  # Use the newer optimise option instead of the deprecated auto-optimise-store
  nix.optimise = {
    automatic = true;
  };

  # ============================================================================
  # System Defaults
  # ============================================================================
  system.defaults = {
    NSGlobalDomain = {
      # Dark mode
      AppleInterfaceStyle = "Dark";
      
      # Key repeat
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      
      # Trackpad
      "com.apple.trackpad.scaling" = 2.0;
    };

    dock = {
      # Auto-hide dock
      autohide = true;
      
      # Small icon size
      tilesize = 36;
      
      # Minimize to application icon
      minimize-to-application = true;
      
      # Show indicator lights
      show-recents = false;
    };

    finder = {
      # Show hidden files
      AppleShowAllFiles = true;
      
      # Show file extensions
      AppleShowAllExtensions = true;
      
      # Use column view
      FXPreferredViewStyle = "clmv";
    };

    CustomUserPreferences = {
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
      "com.apple.finder" = {
        EmptyTrashSecurely = true;
      };
    };
  };

  # ============================================================================
  # Keyboard
  # ============================================================================
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = false;
  };

  # ============================================================================
  # Brew Configuration
  # ============================================================================
  homebrew = {
    enable = true;

    # Homebrew taps (removed deprecated homebrew/cask-fonts)
    taps = [];
    
    onActivation = {
      autoUpdate = false;
      cleanup = "zap";
      upgrade = false;
    };

    brews = [
      # All formulas have been migrated to Nix `environment.systemPackages` for reproducibility.
    ];

    casks = [      
      # Terminals, apps & fonts
      "kitty"
      "ghostty"
    ];

    # Mac App Store apps (requires authentication)
    # masApps = {
    #   Xcode = 497799835;
    # };
  };
}
