# ============================================================================
# ZSH Profile - Environment Setup (login shells)
# ============================================================================

# Timezone
export TZ=Asia/Jakarta

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

# Local machine-specific profile (keep minimal)
[[ -f ~/.zprofile_local ]] && source ~/.zprofile_local

# Local machine profile
[[ -f ~/.zprofile_local ]] && source ~/.zprofile_local
