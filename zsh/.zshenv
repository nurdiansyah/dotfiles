# This file is sourced by *all* zsh shells (login, non-login, interactive and non-interactive).
# Keep this file minimal: export PATH entries or environment variables that must be
# present in every shell (e.g., Volta, Homebrew). Avoid running slow or stateful commands here.
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# Ensure Homebrew bin is available in all shells so `brew` and GUI-installed
# binaries like `starship` are discoverable even in non-login shells.
# Use canonical paths and check for the binary so this is safe to source multiple times.
if [ -x /opt/homebrew/bin/brew ]; then
  export PATH="/opt/homebrew/bin:$PATH"
elif [ -x /usr/local/bin/brew ]; then
  export PATH="/usr/local/bin:$PATH"
fi
