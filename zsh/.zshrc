# ============================================================================
# ZSH Configuration
# ============================================================================
# Path to oh-my-zsh installation
export ZSH="${HOME}/.oh-my-zsh"

# Use Starship prompt if available, otherwise fall back to Powerlevel10k instant prompt
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
else
  if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
  fi
fi

# Theme is managed by Starship (if available); leave Oh My Zsh theme unset to avoid conflicts
ZSH_THEME=""

# Oh-my-zsh plugins
plugins=(git kustomize kubectl)

# Oh My Zsh removed — plugins can be provided by Home Manager or sourced selectively

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

# Node paths (add bin dirs explicitly)
export PATH="${NPM_HOME}/bin:${PNPM_HOME}/bin:${PATH}"
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
# Paths
# DOTFILES points to the checked-out dotfiles repo
export DOTFILES="${HOME}/.dotfiles"
export PROJECTS="${HOME}/projects"

alias dots='cd "$DOTFILES"'
alias proj='cd "$PROJECTS"'

# Safe helper to create directories recursively without overriding system mkdir
mkd() { mkdir -p -- "$@"; }

# ============================================================================
# MongoDB
# ============================================================================
export MONGOMS_DOWNLOAD_DIR="${HOME}/.cache"

# ============================================================================
# Brew & macOS
# ============================================================================
export HOMEBREW_NO_AUTO_UPDATE=true

# libpq (PostgreSQL client libs) — only add if Homebrew and libpq exist
if command -v brew >/dev/null 2>&1; then
  if [[ -d "$(brew --prefix libpq)/bin" ]]; then
    export PATH="$(brew --prefix libpq)/bin:${PATH}"
  fi
fi

# ============================================================================
# Shell Plugins & Completions
# ============================================================================
# Zsh autosuggestions (guarded if Homebrew present)
if command -v brew >/dev/null 2>&1; then
  prefix="$(brew --prefix)"
  [[ -f "${prefix}/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
    source "${prefix}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

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

# pnpm completion (guarded)
fpath=(~/.zsh $fpath)
[[ -f ~/.zsh/_pnpm_completion ]] && source ~/.zsh/_pnpm_completion

# ============================================================================
# Misc Tools
# ============================================================================
# Mcfly (shell history search)
if [ -x /opt/homebrew/bin/mcfly ]; then
  eval "$(/opt/homebrew/bin/mcfly init zsh)"
elif command -v mcfly >/dev/null 2>&1; then
  eval "$(mcfly init zsh)"
fi

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

# Starship preferred; Powerlevel10k kept as a fallback if Starship isn't installed
if command -v starship >/dev/null 2>&1; then
  # Configure Starship via ~/.config/starship.toml
  :
else
  [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
  export POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
fi

# ============================================================================
# Custom User Functions & Aliases
# ============================================================================

# Quick edit dotfiles
alias zshconfig='nvim ~/.zshrc'
alias zshprofile='nvim ~/.zsh_profile'

# Directory helpers
alias ll='ls -lah'
# use mkd instead of overriding 'mkdir'
# alias mkdir='mkdir -p'  # disabled to avoid surprising behavior

# Utils
alias reload='source ~/.zshrc'
alias timestamp='date +%Y%m%d_%H%M%S'

# ============================================================================
# Ensure login profile env is available in interactive shells
# ============================================================================
if [[ -f "${HOME}/.zprofile" ]]; then
  source "${HOME}/.zprofile"
fi

# Local Machine-Specific Config (if exists)
[[ -f ~/.zsh_local ]] && source ~/.zsh_local
