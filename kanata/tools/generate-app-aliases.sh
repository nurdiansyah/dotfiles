#!/usr/bin/env bash
set -euo pipefail

# generate-app-aliases.sh
# Usage:
#   ./generate-app-aliases.sh [--bundle|-b] "Visual Studio Code" Safari iTerm
# Outputs defalias lines (kanata config) to stdout.

show_help() {
  cat <<EOF
Usage: $0 [--bundle|-b] <App Name> [<App Name> ...]

Options:
  -b, --bundle   Prefer opening by bundle id (open -b <bundle>) if found
  -h, --help     Show this help

Example:
  $0 "Visual Studio Code" Safari iTerm
  $0 -b "Visual Studio Code"

EOF
}

PREFER_BUNDLE=no
if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  show_help
  exit 0
fi
if [[ ${1:-} == "-b" || ${1:-} == "--bundle" ]]; then
  PREFER_BUNDLE=yes
  shift
fi

if [[ $# -eq 0 ]]; then
  echo "No app names provided. Use --help for usage." >&2
  exit 2
fi

# Known friendly alias map
declare -A KNOWN=(
  ["Visual Studio Code"]=cod
  ["VSCode"]=cod
  ["Mail"]=eml
  ["Terminal"]=trm
  ["iTerm"]=it2
  ["Safari"]=brs
  ["Finder"]=fnd
)

alias_from_name() {
  local name="$1"
  if [[ -n "${KNOWN[$name]:-}" ]]; then
    echo "${KNOWN[$name]}"
    return
  fi
  # derive alias: initials (max 3) or first 3 letters
  IFS=' ' read -r -a parts <<< "$name"
  if [[ ${#parts[@]} -gt 1 ]]; then
    local alias=""
    for p in "${parts[@]}"; do
      alias+="${p:0:1}"
      if [[ ${#alias} -ge 3 ]]; then break; fi
    done
    # lowercase alias (portable)
    echo "$alias" | tr '[:upper:]' '[:lower:]'
  else
    local s="${name//[^[:alnum:]]/}"
    local sub="${s:0:3}"
    echo "$sub" | tr '[:upper:]' '[:lower:]'
  fi
}

find_app_path() {
  local name="$1"
  # exact paths first
  for d in /Applications "$HOME/Applications"; do
    if [[ -d "$d/$name.app" ]]; then
      echo "$d/$name.app"
      return
    fi
  done
  # case-insensitive search in /Applications and ~/Applications
  shopt -s nullglob
  for p in /Applications/*.app "$HOME/Applications"/*.app; do
    local bn
    bn=$(basename "$p" .app)
    local bn_lc
    bn_lc=$(printf "%s" "$bn" | tr '[:upper:]' '[:lower:]')
    local name_lc
    name_lc=$(printf "%s" "$name" | tr '[:upper:]' '[:lower:]')
    if [[ "$bn_lc" == *"$name_lc"* || "$name_lc" == *"$bn_lc"* ]]; then
      echo "$p"
      return
    fi
  done
  # fallback to mdfind by display name
  local md
  md=$(mdfind "kMDItemDisplayName == '$name' && kMDItemKind == 'Application'" | head -n1 || true)
  if [[ -n "$md" ]]; then
    echo "$md"
    return
  fi
  return 1
}

for app in "$@"; do
  app_path=""
  if p=$(find_app_path "$app"); then
    app_path="$p"
  fi

  alias_name=$(alias_from_name "$app")

  if [[ "$PREFER_BUNDLE" == "yes" && -n "$app_path" ]]; then
    bundle=$(mdls -name kMDItemCFBundleIdentifier -raw "$app_path" 2>/dev/null || true)
    if [[ -n "$bundle" && "$bundle" != "(null)" ]]; then
      printf "%s (cmd open -b %s)\n" "$alias_name" "$bundle"
      continue
    fi
  fi

  # default: open by application name (works if name is exact or launcher can find it)
  # ensure proper quoting
  printf "%s (cmd open -a \"%s\")\n" "$alias_name" "$app"
done
