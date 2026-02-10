# Consolidated zsh configuration — single-file `.zshrc`
# Combined from `init.zsh` so everything is in one place.
# Backup and per-machine overrides should be used for local customizations.

# Download Znap, if it's not there yet.
[[ -r ~/Repos/znap/znap.zsh ]] ||
    git clone --depth 1 -- \
        https://github.com/marlonrichert/zsh-snap.git ~/.local/znap
source ~/.local/znap/znap.zsh  # Start Znap

# Helper: convenience wrapper to (attempt to) install/update known plugins via Znap.
# Uses `|| true` so it won't fail shell startup if a subcommand is missing.
zsh_znap_install_plugins() {
  if (( $+commands[znap] )); then
    for repo in marlonrichert/zsh-autocomplete zsh-users/zsh-autosuggestions; do
      znap source "$repo" || true
      znap install "$repo" || true
    done
    echo "Znap: attempted to install/update plugins (check output above)."
  else
    echo "Znap not installed. The top of this file can install it for you (clones to ~/.local/znap)."
    return 1
  fi
}

# Ensure login profile env is available in interactive shells
if [[ -f "${HOME}/.zprofile" ]]; then
  source "${HOME}/.zprofile"
fi

# ==========================================================================
# Neovim profile helpers
# ==========================================================================

nvim_profile() {
  local profile="${1:-javascript}"
  if [[ ! "$profile" =~ ^(javascript|java|devops)$ ]]; then
    echo "Usage: nvim_profile {javascript|java|devops}"
    return 1
  fi

  mkdir -p ~/.config/nvim/state
  echo "$profile" > ~/.config/nvim/state/profile
  echo "✓ Nvim profile set to: $profile"
}

nvim_profile_show() {
  local profile_file="${HOME}/.config/nvim/state/profile"
  if [[ -f "$profile_file" ]]; then
    echo "Current profile: $(cat $profile_file)"
  else
    echo "No profile set (default: javascript)"
  fi
}

# ==========================================================================
# Neovim shortcuts & helpers
# ==========================================================================
alias v='nvim'
alias vim='nvim'
alias vi='nvim'
alias nvimrc='nvim ~/.config/nvim'
alias nvimsync='cd ~/dotfiles/nvim && nvim .'

nvim_format() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: nvim_format <file> [file2] ..."
    return 1
  fi
  nvim -c "lua require('conform').format()" -c "wq" "$@"
}

# ==========================================================================
# Git aliases
# ==========================================================================
alias g='git'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gpl='git pull'
alias gst='git status'
alias glog='git log --oneline -10'
alias gbr='git branch'

# ==========================================================================
# Kubernetes aliases
# ==========================================================================
alias k='kubectl'
alias kg='kubectl get'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'

# ==========================================================================
# Navigation and filesystem helpers
# ==========================================================================
alias dots='cd $HOME/dotfiles'
alias proj='cd $HOME/projects'
alias ll='ls -lah'
alias mkdir='mkdir -p'

# ==========================================================================
# Utilities
# ==========================================================================
alias reload='exec zsh'
alias timestamp='date +%Y%m%d_%H%M%S'

# ==========================================================================
# Node.js
# ==========================================================================
alias npm-global='npm list -g --depth=0'
alias pnpm-global='pnpm list -g --depth=0'

# ==========================================================================
# Shell config editing
# ==========================================================================
# Point to the repo-managed zsh config now that Home Manager is archived
alias zshconfig='nvim ~/.zshrc'
alias dotfiles='cd ~/dotfiles'

# ==========================================================================
# Helper functions
# ==========================================================================

proj_open() {
  if [[ -z "$1" ]]; then
    echo "Usage: proj_open <project-name>"
    return 1
  fi
  cd "$HOME/projects/$1" && nvim .
}

gcp() {
  if [[ -z "$1" ]]; then
    echo "Usage: gcp <message>"
    return 1
  fi
  git add . && git commit -m "$1" && git push
}

pkill_by_name() {
  if [[ -z "$1" ]]; then
    echo "Usage: pkill_by_name <process-name>"
    return 1
  fi
  ps aux | grep "$1" | grep -v grep | awk '{print $2}' | xargs kill -9
}

# Quick edit helpers
alias zshrc='nvim ~/.zshrc'
alias zshprofile='nvim ~/.zsh_profile'

# Machine-specific overrides (if exists)
[[ -f ~/.zsh_local ]] && source ~/.zsh_local

# ==========================================================================
# autocomplete (znap-managed only)
# This repo no longer bundles `zsh-autocomplete`. Install and use Znap (or
# another plugin manager) to enable the plugin. The shell will not source a
# local copy from the repo anymore.
# ==========================================================================
if (( $+commands[znap] )); then
  # Register upstream repo and load it via Znap. `|| true` keeps startup safe
  # even if the znap subcommand is missing.
  znap source marlonrichert/zsh-autocomplete || true
  znap load marlonrichert/zsh-autocomplete || true
fi

# Initialize Starship after PATH and login profile are set
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# ==========================================================================
# autosuggestions (znap-managed only)
# This repo no longer bundles `zsh-autosuggestions`. Install and use Znap (or
# another plugin manager) to enable the plugin. The shell will not source a
# local copy from the repo anymore.
# ==========================================================================
if (( $+commands[znap] )); then
  znap source zsh-users/zsh-autosuggestions || true
  znap load zsh-users/zsh-autosuggestions || true
fi
