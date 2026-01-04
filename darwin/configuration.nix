{ config, pkgs, machine, machineType, ... }:

{
  # System configuration for macOS
  system.stateVersion = 5;
  
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
    exa
    delta

    # Moved from Homebrew brews -> manage via Nix for reproducibility
    bash
    bashInteractive = pkgs.bashInteractive;
    bashCompletion = pkgs.bash-completion;
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

    # Libraries migrated from Homebrew
    ca-certificates
    icu
    krb5
    libgit2
    libpq
    libssh2
    libunistring
    libuv
    lua
    luajit
    luarocks
    luv
    ncurses
    oniguruma
    openssl
    pcre2
    readline
  ];

  # Machine-specific configuration
  imports = [ ./machines.nix ];

  # ============================================================================
  # Nix Configuration
  # ============================================================================
  nix.settings = {
    # Enable flakes
    experimental-features = [ "nix-command" "flakes" ];
    
    # Auto-optimize nix store
    auto-optimise-store = true;
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
      
      # Empty trash securely
      EmptyTrashSecurely = true;
    };

    CustomUserPreferences = {
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
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

    # Ensure fonts tap is available for cask-fonts
    taps = [ "homebrew/cask-fonts" ];
    
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
      "aerospace"
      "ghostty"
      "leader-key"
    ];

    # Mac App Store apps (requires authentication)
    # masApps = {
    #   Xcode = 497799835;
    # };
  };
}
