# Minimal zsh shim — sources the canonical interactive init file
# This file is intentionally small; all aliases, functions, and interactive
# configuration live in `~/.zsh/init.zsh` (deployed by Home Manager).

# Ensure login profile env is available in interactive shells
if [[ -f "${HOME}/.zprofile" ]]; then
  source "${HOME}/.zprofile"
fi

# Source canonical interactive init (functions, aliases, completions)
if [[ -f "${HOME}/.zsh/init.zsh" ]]; then
  source "${HOME}/.zsh/init.zsh"
fi

# Initialize Starship after login profile env is loaded so `starship` is in PATH
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Local Machine-Specific Config (if exists)
[[ -f ~/.zsh_local ]] && source ~/.zsh_local
