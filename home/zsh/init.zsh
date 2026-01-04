# Zsh initialization script sourced by home-manager

# ============================================================================
# Profile Switching for Neovim
# ============================================================================
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

# ============================================================================
# Neovim Shortcuts
# ============================================================================
alias v='nvim'
alias vim='nvim'
alias vi='nvim'
alias nvimrc='nvim ~/.config/nvim'
alias nvimsync='cd ~/.dotfiles/nvim && nvim .'

# Format current file with conform
nvim_format() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: nvim_format <file> [file2] ..."
    return 1
  fi
  nvim -c "lua require('conform').format()" -c "wq" "$@"
}

# ============================================================================
# Git Aliases
# ============================================================================
alias g='git'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gpl='git pull'
alias gst='git status'
alias glog='git log --oneline -10'
alias gbr='git branch'

# ============================================================================
# Kubernetes Aliases
# ============================================================================
alias k='kubectl'
alias kg='kubectl get'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'

# ============================================================================
# Directory Navigation
# ============================================================================
alias dots='cd $HOME/dotfiles'
alias proj='cd $HOME/projects'
alias ll='ls -lah'
alias mkdir='mkdir -p'

# ============================================================================
# Utilities
# ============================================================================
alias reload='exec zsh'
alias timestamp='date +%Y%m%d_%H%M%S'

# ============================================================================
# Node.js
# ============================================================================
alias npm-global='npm list -g --depth=0'
alias pnpm-global='pnpm list -g --depth=0'

# ============================================================================
# Shell Config Editing
# ============================================================================
alias zshconfig='nvim ~/.config/home-manager/home.nix'
alias dotfiles='cd ~/.config/dotfiles'

# ============================================================================
# Functions
# ============================================================================

# cd to project and open in nvim
proj_open() {
  if [[ -z "$1" ]]; then
    echo "Usage: proj_open <project-name>"
    return 1
  fi
  cd "$HOME/projects/$1" && nvim .
}

# Quick git commit & push
gcp() {
  if [[ -z "$1" ]]; then
    echo "Usage: gcp <message>"
    return 1
  fi
  git add . && git commit -m "$1" && git push
}

# Find and kill process by name
pkill_by_name() {
  if [[ -z "$1" ]]; then
    echo "Usage: pkill_by_name <process-name>"
    return 1
  fi
  ps aux | grep "$1" | grep -v grep | awk '{print $2}' | xargs kill -9
}
