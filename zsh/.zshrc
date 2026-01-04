# ============================================================================
# ZSH Configuration
# ============================================================================
# Path to oh-my-zsh installation
export ZSH="${HOME}/.oh-my-zsh"

# Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Theme (using sobole or powerlevel10k)
ZSH_THEME="sobole"

# Oh-my-zsh plugins
plugins=(git kustomize kubectl)

# Source oh-my-zsh
source $ZSH/oh-my-zsh.sh

# ============================================================================
# Language & Locale
# ============================================================================
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# ============================================================================
# Profile Switching for Dotfiles
# ============================================================================
# Switch Nvim profile (javascript, java, devops)
nvim_profile() {
  local profile="${1:-javascript}"
  if [[ ! "$profile" =~ ^(javascript|java|devops)$ ]]; then
    echo "Usage: nvim_profile {javascript|java|devops}"
    return 1
  fi
  
  # Store in state file for Neovim to read
  mkdir -p ~/.config/nvim/state
  echo "$profile" > ~/.config/nvim/state/profile
  echo "✓ Nvim profile set to: $profile"
}

# Show current profile
nvim_profile_show() {
  local profile_file="${HOME}/.config/nvim/state/profile"
  if [[ -f "$profile_file" ]]; then
    echo "Current profile: $(cat $profile_file)"
  else
    echo "No profile set (default: javascript)"
  fi
}

# ============================================================================
# Neovim & Editor
# ============================================================================
export EDITOR='nvim'
export VISUAL='nvim'

# FZF configuration
export FZF_DEFAULT_OPTS='--height 40% --reverse --border'
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'

# Nvim shortcuts
alias v='nvim'
alias vi='nvim'
alias vim='nvim'
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
# Node.js & NPM
# ============================================================================
export NPM_HOME="${HOME}/.npm-packages"
export PNPM_HOME="${HOME}/.pnpm"

# Node paths
export PATH="${NPM_HOME}/bin:${PNPM_HOME}:${PATH}"
export NODE_OPTIONS="--max_old_space_size=4096"

# NPM/PNPM tokens (read from secure location or env)
# export NPM_TOKEN="your_token_here"
# export GITHUB_TOKEN="your_token_here"

# Node shortcuts
alias n='node'
alias npm-global='npm list -g --depth=0'
alias pnpm-global='pnpm list -g --depth=0'

# ============================================================================
# Python
# ============================================================================
# Python virtual environment (if exists)
[[ -f ~/.config/python-venv/bin/activate ]] && source ~/.config/python-venv/bin/activate
export PATH="${HOME}/Library/Python/3.9/bin:${PATH}"

# ============================================================================
# Java & Build Tools
# ============================================================================
# SDKMAN (must be at end for SDKMAN, but we'll keep ordering here)
export SDKMAN_DIR="${HOME}/.sdkman"
[[ -s "${HOME}/.sdkman/bin/sdkman-init.sh" ]] && source "${HOME}/.sdkman/bin/sdkman-init.sh"

# Gradle
export PATH="/usr/local/opt/gradle@7/bin:${PATH}"

# ============================================================================
# Kubernetes & DevOps
# ============================================================================
# kubectl plugins directory
export KUBECONFIG="${HOME}/.kube/config"

# k8s helpers
alias k='kubectl'
alias kg='kubectl get'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'

# ============================================================================
# Git Shortcuts
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
# Directory Navigation
# ============================================================================
export DOTFILES="${HOME}/dotfiles"
export PROJECTS="${HOME}/projects"

alias dots='cd $DOTFILES'
alias proj='cd $PROJECTS'

# ============================================================================
# MongoDB
# ============================================================================
export MONGOMS_DOWNLOAD_DIR="${HOME}/.cache"

# ============================================================================
# Brew & macOS
# ============================================================================
export HOMEBREW_NO_AUTO_UPDATE=true

# libpq (PostgreSQL client libs)
export PATH="$(brew --prefix libpq)/bin:${PATH}"

# ============================================================================
# Shell Plugins & Completions
# ============================================================================
# Zsh autosuggestions
[[ -f "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
  source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# FZF completion
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# iTerm2 shell integration
[[ -e "${HOME}/.iterm2_shell_integration.zsh" ]] && source "${HOME}/.iterm2_shell_integration.zsh"

# Tabtab CLI completion
[[ -f ~/.config/tabtab/zsh/__tabtab.zsh ]] && source ~/.config/tabtab/zsh/__tabtab.zsh

# Rush.js completion
(( ${+commands[rush]} )) && {
  _rush_completion() {
    compadd -- $(rush tab-complete --position ${CURSOR} --word "${BUFFER}" 2>>/dev/null)
  }
  compdef _rush_completion rush
}

# pnpm completion
fpath=(~/.zsh $fpath)
[[ -f ~/.zsh/_pnpm_completion ]] && source ~/.zsh/_pnpm_completion

# ============================================================================
# Misc Tools
# ============================================================================
# Mcfly (shell history search)
command -v mcfly >/dev/null && eval "$(mcfly init zsh)"

# Windsurf
export PATH="${HOME}/.codeium/windsurf/bin:${PATH}"

# Perl (if installed via cpan)
export PATH="${HOME}/perl5/bin:${PATH}"
export PERL5LIB="${HOME}/perl5/lib/perl5:${PERL5LIB}"
export PERL_LOCAL_LIB_ROOT="${HOME}/perl5:${PERL_LOCAL_LIB_ROOT}"

# Antigravity
export PATH="${HOME}/.antigravity/antigravity/bin:${PATH}"

# JetBrains VM options
[[ -f "${HOME}/.jetbrains.vmoptions.sh" ]] && source "${HOME}/.jetbrains.vmoptions.sh"

# ============================================================================
# PowerLevel10k (if using)
# ============================================================================
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
export POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true

# ============================================================================
# Custom User Functions & Aliases
# ============================================================================

# Quick edit dotfiles
alias zshconfig='nvim ~/.zshrc'
alias zshprofile='nvim ~/.zsh_profile'

# Directory helpers
alias ll='ls -lah'
alias mkdir='mkdir -p'

# Utils
alias reload='source ~/.zshrc'
alias timestamp='date +%Y%m%d_%H%M%S'

# ============================================================================
# Local Machine-Specific Config (if exists)
# ============================================================================
[[ -f ~/.zsh_local ]] && source ~/.zsh_local
