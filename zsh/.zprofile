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
# HOMEBREW_NO_AUTO_UPDATE may be set in your environment (e.g., CI or personal configs).
# This file is sourced for *login* shells (e.g., Terminal.app sessions). We run
# `brew shellenv` here so login sessions receive Homebrew's PATH and environment.
# For non-login or system-level shells (e.g., GUI apps or some VSCode shells),
# see `.zshenv` which can prepend Homebrew's bin early in the session.
# Prefer explicit brew binary location when brew is not yet in PATH.
BREW_BIN=""
if [ -x /opt/homebrew/bin/brew ]; then
  BREW_BIN=/opt/homebrew/bin/brew
elif [ -x /usr/local/bin/brew ]; then
  BREW_BIN=/usr/local/bin/brew
else
  BREW_BIN="$(command -v brew 2>/dev/null || true)"
fi

if [ -n "$BREW_BIN" ] && [ -x "$BREW_BIN" ]; then
  # Avoid re-evaluation in the same session
  if [ -z "${BREW_SHELLENV_DONE:-}" ]; then
    eval "$("$BREW_BIN" shellenv)"
    BREW_SHELLENV_DONE=1
  fi
fi

# FZF defaults
# Managed via shell configuration or local session variables (adjust as needed)

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

# Created by `pipx` on 2026-01-07 09:56:08
export PATH="$PATH:/Users/nurdiansyah/.local/bin"
