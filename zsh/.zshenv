export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# Ensure Homebrew bin is available in all shells so `brew` and GUI-installed
# binaries like `starship` are discoverable even in non-login shells.
if [ -x /opt/homebrew/bin/brew ]; then
  export PATH="/opt/homebrew/bin:$PATH"
elif [ -x /usr/local/bin/brew ]; then
  export PATH="/usr/local/bin:$PATH"
fi
