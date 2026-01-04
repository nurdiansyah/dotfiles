{ pkgs, username, machineType ? "macmini" }:

{
  # Home Manager Configuration
  home.stateVersion = "24.05";
  home.username = username;
  home.homeDirectory = /Users/${username};

  # Create backups automatically when Home Manager would overwrite files
  home-manager.backupFileExtension = ".before-nix-darwin";

  # Machine type for conditional configurations
  _module.args.machineType = machineType;

  # ============================================================================
  # Shell Configuration
  # ============================================================================
  programs.zsh = {
    enable = true;
    initExtra = builtins.readFile ./zsh/init.zsh;
    dotDir = "/Users/nurdiansyah/dotfiles";
    
    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh/plugins/powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "zsh-autosuggestions";
        src = pkgs.zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
    ];
  };

  programs.zsh.oh-my-zsh = {
    enable = true;
    plugins = [ "git" "kubectl" "kustomize" ];
    theme = "sobole";
  };

  # ============================================================================
  # Neovim
  # ============================================================================
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    
    # Lazy.nvim will be managed in init.lua
    extraConfig = builtins.readFile ../nvim/init.lua;
  };

  # ============================================================================
  # Git Configuration
  # ============================================================================
  programs.git = {
    enable = true;
    userName = "Nurdiansyah";
    userEmail = "nurdiansyah@example.com";
    
    extraConfig = {
      core.editor = "nvim";
      pull.rebase = true;
      fetch.prune = true;
      init.defaultBranch = "main";
    };

    aliases = {
      st = "status";
      co = "checkout";
      br = "branch";
      ci = "commit";
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
      visual = "log --graph --oneline --all";
    };
  };

  programs.git.ignores = [ ".DS_Store" ".direnv" "*.swp" ];

  # ============================================================================
  # Tmux
  # ============================================================================
  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
    baseIndex = 1;
    clock24 = true;
    
    extraConfig = builtins.readFile ../tmux/.tmux.conf;
  };

  # ============================================================================
  # Home Directory Organization
  # ============================================================================
  # Ensure common user directories exist via home.file entries
  # home.file."projects/.keep".text = "";
  home.file."dotfiles/.keep".text = "";

  # ============================================================================
  # Environment Variables
  # ============================================================================
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    
    # FZF
    FZF_DEFAULT_OPTS = "--height 40% --reverse --border";
    FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git";
    
    # Node.js
    NODE_OPTIONS = "--max_old_space_size=4096";
    
    # Timezone
    TZ = "Asia/Jakarta";
    LC_ALL = "en_US.UTF-8";
    LANG = "en_US.UTF-8";
  };

  # ============================================================================
  # Direnv for .envrc files
  # ============================================================================
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };

  # ============================================================================
  # FZF
  # ============================================================================
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # ============================================================================
  # Bat (syntax highlighting for cat)
  # ============================================================================
  programs.bat = {
    enable = true;
    config.theme = "tokyonight";
  };

  # ============================================================================
  # Starship Prompt (alternative to powerlevel10k)
  # ============================================================================
  # Uncomment to use Starship instead of Powerlevel10k
  # programs.starship = {
  #   enable = true;
  #   enableZshIntegration = true;
  #   settings = {
  #     add_newline = false;
  #   };
  # };

  # ============================================================================
  # Session Variables & Functions
  # ============================================================================
  home.sessionPath = [
    "$HOME/.npm-packages/bin"
    "$HOME/.pnpm"
    "$HOME/.local/bin"
  ];

  # ============================================================================
  # Home Packages (user-scoped)
  # Keep developer tools that you want per-user here. System/global packages
  # are declared in darwin/configuration.nix under environment.systemPackages.
  # ============================================================================
  home.packages = [];


  # ============================================================================
  # Misc Programs
  # ============================================================================
  programs.home-manager.enable = true;
}
