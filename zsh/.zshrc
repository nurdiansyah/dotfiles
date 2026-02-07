# Consolidated zsh configuration — single-file `.zshrc`
# Combined from `init.zsh` so everything is in one place.
# Backup and per-machine overrides should be used for local customizations.

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
# autocomplete (git submodule)
# If the submodule is present in the repo layout, source it for completions.
# ==========================================================================
if [ -f "$HOME/dotfiles/zsh/autocomplete/zsh-autocomplete.plugin.zsh" ]; then
  # optional: any early config can go here
  source "$HOME/dotfiles/zsh/autocomplete/zsh-autocomplete.plugin.zsh"
fi

# Initialize Starship after PATH and login profile are set
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# ==========================================================================
# autosuggestions (git submodule)
# If the submodule is present in the repo layout, source it for suggestions.
# ==========================================================================
if [ -f "$HOME/dotfiles/zsh/autosuggestions/zsh-autosuggestions.zsh" ]; then
  # optional: set highlight style before sourcing
  export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
  source "$HOME/dotfiles/zsh/autosuggestions/zsh-autosuggestions.zsh"
fi
