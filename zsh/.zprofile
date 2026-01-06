# ============================================================================
# ZSH Profile - Environment Setup (login shells)
# ============================================================================

# Timezone
export TZ=Asia/Jakarta

# Locale
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# MongoDB cache dir
export MONGOMS_DOWNLOAD_DIR="${HOME}/.cache"

# npm
export NPM_HOME="${HOME}/.npm-packages"
export PNPM_HOME="${HOME}/.pnpm"
# Add user npm/pnpm bins to PATH
export PATH="${NPM_HOME}/bin:${PNPM_HOME}/bin:${PATH}"
export NODE_OPTIONS="--max_old_space_size=4096"

# JetBrains IDEs
export PATH="/Applications/RustRover.app/Contents/MacOS:${PATH}"

# Homebrew
# HOMEBREW_NO_AUTO_UPDATE is managed by Home Manager via home.sessionVariables

# FZF defaults
# Managed by Home Manager's `home.sessionVariables`

# Python venv activation remains in zprofile (login-time activation)
[[ -f ~/.config/python-venv/bin/activate ]] && source ~/.config/python-venv/bin/activate

# Initialize Starship for interactive sessions (guarded to avoid double-init)
# - Runs only in interactive shells
# - Uses STARSHIP_INIT_DONE to avoid re-initializing during the same session
if [[ $- == *i* ]] && [[ -z "${STARSHIP_INIT_DONE:-}" ]]; then
  if command -v starship >/dev/null 2>&1; then
    STARSHIP_INIT_DONE=1
    eval "$(starship init zsh)"
  fi
fi

# Local machine profile
[[ -f ~/.zprofile_local ]] && source ~/.zprofile_local
