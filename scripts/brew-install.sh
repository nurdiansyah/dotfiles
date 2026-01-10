#!/usr/bin/env bash
set -euo pipefail

# scripts/brew-install.sh
# Encapsulate Brewfile/brew bundle operations for the dotfiles repo.

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
BREWFILE_PATH="$REPO_ROOT/Brewfile"
DO_UPDATE=0
DO_COMMIT=0
ASSUME_YES=0
DRY_RUN=0
PACKAGES=()

print_usage() {
  cat <<'EOF'
Usage: $(basename "$0") [options] [packages...]

Options:
  --file <path>        Path to Brewfile (defaults to repo root/Brewfile)
  --update             Append missing packages to Brewfile
  --commit             Commit Brewfile changes (implies --update)
  --yes, -y            Assume yes for prompts
  --dry-run            Print actions without executing
  --help               Show this help

Examples:
  $(basename "$0") --update --commit git node
  $(basename "$0") --dry-run curl
EOF
}

# Simple logger helpers
info() { printf 'info: %s\n' "$*"; }
err() { printf 'error: %s\n' "$*" >&2; }

# Parse args
while [ "$#" -gt 0 ]; do
  case "$1" in
    --file)
      shift; BREWFILE_PATH="$1"; shift;;
    --update)
      DO_UPDATE=1; shift;;
    --commit)
      DO_COMMIT=1; DO_UPDATE=1; shift;;
    --yes|-y)
      ASSUME_YES=1; shift;;
    --dry-run)
      DRY_RUN=1; shift;;
    --help)
      print_usage; exit 0;;
    --*)
      err "Unknown option: $1"; print_usage; exit 1;;
    *)
      PACKAGES+=("$1"); shift;;
  esac
done

# Ensure Brewfile* behavior is understandable
if [ ! -f "$BREWFILE_PATH" ] && [ $DO_UPDATE -eq 1 ]; then
  err "Brewfile not found at $BREWFILE_PATH; cannot update a missing Brewfile"
  exit 1
fi

# Show actions in dry-run mode
run_or_echo() {
  if [ $DRY_RUN -eq 1 ]; then
    info "DRY RUN: $*"
  else
    eval "$*"
  fi
}

# Append missing packages to Brewfile (preserves formatting by using brew/cask lines)
append_missing() {
  local missing=()
  for pkg in "${PACKAGES[@]}"; do
    if [ -f "$BREWFILE_PATH" ]; then
      if grep -E '^[[:space:]]*(brew|cask) ' "$BREWFILE_PATH" | sed -E 's/^[[:space:]]*(brew|cask)[[:space:]]+[\"\'"']?([^\"\'"'""[:space:],]+).*/\2/' | grep -xq -- "$pkg"; then
        info "Package $pkg already present in $BREWFILE_PATH"
      else
        missing+=("$pkg")
      fi
    else
      missing+=("$pkg")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    info "Missing packages to append: ${missing[*]}"
    if [ $ASSUME_YES -ne 1 ]; then
      read -r -p "Append these packages to $BREWFILE_PATH? [Y/n] " ans || true
      case "$ans" in
        [Nn]*) info "Skipping append"; return 0;;
      esac
    fi

    backup="$BREWFILE_PATH.bak.$(date -u +%Y%m%dT%H%M%SZ)"
    run_or_echo "cp \"$BREWFILE_PATH\" \"$backup\""
    info "Created backup: $backup"
    for p in "${missing[@]}"; do
      run_or_echo "echo \"brew \"\"$p\"\"\" >> \"$BREWFILE_PATH\""
    done
    info "Appended ${#missing[@]} packages to $BREWFILE_PATH"
    APPENDED_PKGS=("${missing[@]}")
    # Emit machine-readable info for callers
    printf 'BREW-INFO: APPENDED %s\n' "${APPENDED_PKGS[*]}"
    printf 'BREW-INFO: BACKUP %s\n' "$backup"
  else
    info "No missing packages to append"
  fi
}

# Run brew bundle on given file
run_bundle() {
  local file="$1"
  if ! command -v brew >/dev/null 2>&1; then
    err "Homebrew not found; please install Homebrew to run 'brew bundle --file=$file'"
    return 1
  fi
  info "Running: brew bundle --file=$file"
  run_or_echo "brew bundle --file=\"$file\" || true"
  # Emit used marker for callers
  printf 'BREW-INFO: USED %s\n' "$file"
}

# Commit Brewfile if changes detected
commit_brewfile() {
  if ! command -v git >/dev/null 2>&1; then
    err "Git not found; cannot commit Brewfile automatically"
    return 1
  fi
  if git -C "$(dirname "$BREWFILE_PATH")" status --porcelain --untracked-files=normal | grep -q "$(basename "$BREWFILE_PATH")"; then
    msg="chore(brewfile): add ${APPENDED_PKGS[*]:-}"
    run_or_echo "git -C \"$(dirname \"$BREWFILE_PATH\")\" add \"$(basename \"$BREWFILE_PATH\")\""
    if run_or_echo "git -C \"$(dirname \"$BREWFILE_PATH\")\" commit -m \"$msg\""; then
      BREWFILE_COMMIT=$(git -C "$(dirname "$BREWFILE_PATH")" rev-parse --short HEAD 2>/dev/null || true)
      info "Committed Brewfile changes: $BREWFILE_COMMIT"
    # Emit machine-readable commit marker
    printf 'BREW-INFO: COMMIT %s\n' "$BREWFILE_COMMIT"
    else
      err "Failed to commit Brewfile changes; please commit manually"
      git -C "$(dirname "$BREWFILE_PATH")" status --porcelain --untracked-files=normal | sed 's/^/  /' || true
    fi
  else
    info "No changes to Brewfile to commit"
  fi
}

# Main execution flow
if [ ${#PACKAGES[@]} -eq 0 ] && [ $DO_UPDATE -eq 0 ]; then
  # No packages specified; just run bundle on Brewfile if present
  if [ -f "$BREWFILE_PATH" ]; then
    run_bundle "$BREWFILE_PATH"
    exit $?
  else
    err "No Brewfile found at $BREWFILE_PATH and no packages specified"
    exit 1
  fi
fi

# If packages specified and update requested, append them
if [ ${#PACKAGES[@]} -gt 0 ] && [ $DO_UPDATE -eq 1 ]; then
  append_missing
fi

# If packages specified but no repo Brewfile, create temporary Brewfile
if [ ${#PACKAGES[@]} -gt 0 ] && [ ! -f "$BREWFILE_PATH" ]; then
  tmpfile="$(mktemp -t brewfile.XXXXXXXX)"
  for p in "${PACKAGES[@]}"; do
    run_or_echo "echo \"brew \"\"$p\"\"\" >> \"$tmpfile\""
  done
  run_bundle "$tmpfile"
  run_or_echo "rm -f \"$tmpfile\""
  exit 0
fi

# Otherwise run bundle on the (possibly updated) Brewfile
run_bundle "$BREWFILE_PATH"

# Optionally commit
if [ $DO_COMMIT -eq 1 ]; then
  commit_brewfile
fi

exit 0
