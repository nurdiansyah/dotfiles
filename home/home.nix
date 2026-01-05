{ pkgs, username, machineType ? "macmini" }:

{
  # Home Manager Configuration
  home.stateVersion = "24.05";
  home.username = username;
  home.homeDirectory = "/Users/${username}";

  # Machine type for conditional configurations
  _module.args.machineType = machineType;

  # ============================================================================
  # Shell Configuration
  # ============================================================================
  programs.zsh = {
    enable = true;
    initContent = builtins.readFile ./zsh/init.zsh;
    dotDir = "/Users/nurdiansyah/dotfiles";
    
    plugins = [];
  };

  # Oh My Zsh is intentionally disabled; plugins and prompt pieces are managed by
  # Home Manager entries and packages in `home.packages`.
  programs.zsh.oh-my-zsh = {
    enable = false;
  };

  # ============================================================================
  # Zsh dotfiles (deploy interactive and login shells from repo)
  # - `zsh/.zshrc` contains interactive configuration (aliases, completions)
  # - `zsh/.zprofile` contains login-time environment setup (PATH, TZ, exports)
  # These files are managed by Home Manager so activation installs them into the
  # user's home directory and avoids clobber errors (backups are created).
  home.file.".zshrc".text = builtins.readFile ./zsh/.zshrc;
  home.file.".zprofile".text = builtins.readFile ./zsh/.zprofile;

  # Starship prompt configuration (managed by Home Manager)
  # Moved to top-level `home/` for discoverability and to keep home-managed
  # configuration files grouped together. See `home/README.md` for details.
  home.file.".config/starship.toml".text = builtins.readFile ./starship.toml;

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
    settings = {
      user = {
        name = "Nurdiansyah";
        email = "nur.diansyah.ckt@gmail.com";
      };

      core = {
        editor = "nvim";
      };

      pull = {
        rebase = true;
      };

      fetch = {
        prune = true;
      };

      init = {
        defaultBranch = "main";
      };

      alias = {
        st = "status";
        co = "checkout";
        br = "branch";
        ci = "commit";
        unstage = "reset HEAD --";
        last = "log -1 HEAD";
        visual = "log --graph --oneline --all";
      };
    };
  };

  programs.git.ignores = [ ".DS_Store" ".direnv" "*.swp" ];

  # ============================================================================
  # Tmux
  # ============================================================================
  programs.tmux = {
    enable = false;
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

  # Ensure nvim state file exists for profile switching (default: javascript)
  home.file.".config/nvim/state/profile".text = "javascript";



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
    NPM_HOME = "/Users/${username}/.npm-packages";
    PNPM_HOME = "/Users/${username}/.pnpm";

    # Timezone & locale
    TZ = "Asia/Jakarta";
    LC_ALL = "en_US.UTF-8";
    LANG = "en_US.UTF-8";

    # Homebrew
    HOMEBREW_NO_AUTO_UPDATE = "1";

    # Perl envs
    PERL5LIB = "/Users/${username}/perl5/lib/perl5";
    PERL_LOCAL_LIB_ROOT = "/Users/${username}/perl5";
    PERL_MB_OPT = "--install_base \"/Users/${username}/perl5\"";
    PERL_MM_OPT = "INSTALL_BASE=/Users/${username}/perl5";

    # Misc
    MONGOMS_DOWNLOAD_DIR = "/Users/${username}/.cache";
  };

  # Session PATH entries (user bins and app dirs)
  home.sessionPath = [
    "/Users/${username}/.npm-packages/bin"
    "/Users/${username}/.pnpm/bin"
    "/Users/${username}/.local/bin"
    "/Users/${username}/perl5/bin"
    "/Users/${username}/Library/Python/3.9/bin"
    "/Applications/RustRover.app/Contents/MacOS"
  ];

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
  # Home Packages (user-scoped)
  # Keep developer tools that you want per-user here. System/global packages
  # are declared in darwin/configuration.nix under environment.systemPackages.
  # ============================================================================
  home.packages = with pkgs; [
    starship
  ];


  # ============================================================================
  # Misc Programs
  # ============================================================================
  programs.home-manager.enable = true;
}
