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
export HOMEBREW_NO_AUTO_UPDATE=true

# FZF defaults (env vars are safe in login shell)
export FZF_DEFAULT_OPTS='--height 40% --reverse --border'
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'

# Python venv (login shells should activate envs if needed)
[[ -f ~/.config/python-venv/bin/activate ]] && source ~/.config/python-venv/bin/activate
export PATH="${HOME}/Library/Python/3.9/bin:${PATH}"

# Perl (cpan packages)
export PATH="${HOME}/perl5/bin:${PATH}"
export PERL5LIB="${HOME}/perl5/lib/perl5:${PERL5LIB}"
export PERL_LOCAL_LIB_ROOT="${HOME}/perl5:${PERL_LOCAL_LIB_ROOT}"
export PERL_MB_OPT="--install_base \"${HOME}/perl5\""
export PERL_MM_OPT="INSTALL_BASE=${HOME}/perl5"

# PostgreSQL libs (guarded)
if command -v brew >/dev/null 2>&1 && [[ -d "$(brew --prefix libpq)/bin" ]]; then
  export PATH="$(brew --prefix libpq)/bin:${PATH}"
fi

# Local machine profile
[[ -f ~/.zprofile_local ]] && source ~/.zprofile_local
