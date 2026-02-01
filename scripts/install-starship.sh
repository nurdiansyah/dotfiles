#!/usr/bin/env bash
set -euo pipefail

# scripts/install-starship.sh
# Create a symlink from repo starship/starship.toml to ~/.config/starship.toml

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SRC="$REPO_ROOT/starship/starship.toml"
DEST="$HOME/.config/starship.toml"
ASSUME_YES=0
FORCE=0
DRY_RUN=0

print_usage() {
  cat <<'EOF'
Usage: install-starship.sh [--yes] [--force] [--dry-run]

Options:
  --yes, -y     Assume yes for prompts (non-interactive)
  --force, -f   Overwrite existing file/symlink at destination
  --dry-run     Print actions without making changes
  --help        Show this help
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --yes|-y) ASSUME_YES=1; shift ;;
    --force|-f) FORCE=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --help) print_usage; exit 0;;
    *) echo "Unknown arg: $1"; print_usage; exit 1 ;;
  esac
done

if [ ! -f "$SRC" ]; then
  echo "error: source config not found at $SRC" >&2
  exit 1
fi

# Ensure destination dir exists
if [ "$DRY_RUN" -eq 0 ]; then
  mkdir -p "$(dirname "$DEST")"
fi

# Check for existing dest
if [ -e "$DEST" ] || [ -L "$DEST" ]; then
  if [ "$FORCE" -eq 1 ]; then
    action="rm -f \"$DEST\" && ln -s \"$SRC\" \"$DEST\""
    info_msg="Overwriting existing $DEST"
  else
    if [ "$ASSUME_YES" -eq 1 ]; then
      user_ans=y
    else
      read -r -p "$DEST already exists. Overwrite? [y/N] " user_ans || user_ans=n
    fi
    case "$user_ans" in
      [Yy]*) action="rm -f \"$DEST\" && ln -s \"$SRC\" \"$DEST\""; info_msg="Overwriting $DEST" ;;
      *) echo "Skipping; no changes made."; exit 0 ;;
    esac
  fi
else
  action="ln -s \"$SRC\" \"$DEST\""
  info_msg="Creating symlink $DEST -> $SRC"
fi

if [ "$DRY_RUN" -eq 1 ]; then
  echo "DRY RUN: $info_msg"
  echo "DRY RUN: would run: $action"
  exit 0
fi

echo "$info_msg"
# Execute
bash -c "$action"

echo "Done. To test: STARSHIP_CONFIG=\"$DEST\" starship prompt"
