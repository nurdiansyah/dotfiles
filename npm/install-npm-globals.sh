#!/usr/bin/env bash
set -euo pipefail

# idempotent installer for npm/pnpm/yarn global CLIs using a manifest file
# Usage: install-npm-globals.sh [--manager=auto|npm|pnpm|yarn] [--dry-run] [--yes] [manifest]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_FILE=""
MANAGER="auto"
DRY_RUN=0
ASSUME_YES=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --manager=*) MANAGER="${1#--manager=}"; shift ;;
    --manager)
      if [ "$#" -lt 2 ]; then
        echo "Missing value for --manager" >&2; exit 1
      fi
      MANAGER="$2"; shift 2 ;;
    -m)
      if [ "$#" -lt 2 ]; then
        echo "Missing value for -m" >&2; exit 1
      fi
      MANAGER="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --yes) ASSUME_YES=1; shift ;;
    --help|-h) echo "Usage: $0 [--manager=auto|npm|pnpm|yarn] [--dry-run] [--yes] [manifest]"; exit 0 ;;
    *) MANIFEST_FILE="$1"; shift ;;
  esac
done

# default manifest if none provided
if [ -z "${MANIFEST_FILE}" ]; then
  MANIFEST_FILE="$SCRIPT_DIR/npm-globals.txt"
fi

if [ ! -f "$MANIFEST_FILE" ]; then
  echo "Manifest not found: $MANIFEST_FILE" >&2
  exit 1
fi

# Detect manager if auto
if [ "$MANAGER" = "auto" ]; then
  if command -v pnpm >/dev/null 2>&1; then
    MANAGER=pnpm
  elif command -v npm >/dev/null 2>&1; then
    MANAGER=npm
  elif command -v yarn >/dev/null 2>&1; then
    MANAGER=yarn
  else
    echo "No supported package manager found (pnpm, npm, yarn). Install one and retry." >&2
    exit 1
  fi
fi

# ensure selected manager exists
case "$MANAGER" in
  npm)
    if ! command -v npm >/dev/null 2>&1; then
      echo "Selected manager 'npm' not found; please install Node/npm or choose a different manager" >&2
      exit 1
    fi
    ;;
  pnpm)
    if ! command -v pnpm >/dev/null 2>&1; then
      echo "Selected manager 'pnpm' not found; please install pnpm or choose a different manager" >&2
      exit 1
    fi
    ;;
  yarn)
    if ! command -v yarn >/dev/null 2>&1; then
      echo "Selected manager 'yarn' not found; please install yarn or choose a different manager" >&2
      exit 1
    fi
    ;;
  *)
    echo "Unknown manager: $MANAGER" >&2; exit 1 ;;
esac

# Defaults for user prefix dirs
NPM_HOME="${NPM_HOME:-$HOME/.npm-packages}"
PNPM_HOME="${PNPM_HOME:-$HOME/.pnpm}"

mkdir -p "$NPM_HOME" "$PNPM_HOME"

echo "Using manager: $MANAGER"
echo "Manifest: $MANIFEST_FILE"

# helper to run or echo
run_cmd() {
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "+ $*"
  else
    echo "+ $*"; eval "$@"
  fi
}

# read manifest and iterate
installed_count=0
skipped_count=0
failed_count=0

while IFS= read -r line || [ -n "$line" ]; do
  pkg="$(echo "$line" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
  # skip comments and empty lines
  [ -z "$pkg" ] && continue
  case "$pkg" in
    \#*) continue ;;
  esac

  # check if installed
  already_installed=1
  if [ "$MANAGER" = "npm" ]; then
    if npm ls -g --depth=0 "$pkg" >/dev/null 2>&1; then
      already_installed=0
    fi
  elif [ "$MANAGER" = "pnpm" ]; then
    if pnpm list -g --depth=0 "$pkg" >/dev/null 2>&1; then
      already_installed=0
    fi
  else
    # yarn fallback: try to see if it's in global list
    if yarn global list --pattern "$(echo "$pkg" | sed 's/@.*//')" 2>/dev/null | grep -q "$(echo "$pkg" | sed 's/@.*//')"; then
      already_installed=0
    fi
  fi

  if [ $already_installed -eq 0 ]; then
    echo "Skipping already-installed: $pkg"
    skipped_count=$((skipped_count+1))
    continue
  fi

  # prompt if needed
  if [ $ASSUME_YES -eq 0 ] && [ $DRY_RUN -eq 0 ]; then
    read -r -p "Install $pkg using $MANAGER? [Y/n] " ans
    case "$ans" in
      [Nn]*) echo "Skipping $pkg"; skipped_count=$((skipped_count+1)); continue ;;
    esac
  fi

  # install using chosen manager and user prefix where applicable
  if [ "$MANAGER" = "npm" ]; then
    # Use npm with explicit prefix to avoid sudo
    CMD="NPM_CONFIG_PREFIX=\"$NPM_HOME\" npm install -g \"$pkg\""
  elif [ "$MANAGER" = "pnpm" ]; then
    CMD="pnpm add -g \"$pkg\" --global-dir \"$PNPM_HOME\""
  else
    CMD="yarn global add \"$pkg\""
  fi

  if run_cmd "$CMD"; then
    installed_count=$((installed_count+1))
  else
    echo "Failed to install $pkg" >&2
    failed_count=$((failed_count+1))
  fi

done < "$MANIFEST_FILE"

echo "\nSummary: installed=$installed_count skipped=$skipped_count failed=$failed_count"

if [ $failed_count -gt 0 ]; then
  exit 2
fi
