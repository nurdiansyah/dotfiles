#!/usr/bin/env bash
set -euo pipefail

# install.sh
# Install selected external dependencies (macOS/Homebrew), with flags or interactive mode.

HEREROCKS_DIR="$HOME/.local/share/nvim/lazy-rocks/hererocks"

BREW_REQUIRED=()
DO_HEREROCKS=0
DO_PYPNVIM=0
DO_BREWFILE=0
DO_NPM=0
DO_UPDATE_BREWFILE=0
DO_COMMIT_BREWFILE=0
DO_CONFIG_PRESS_AND_HOLD=0
ASSUME_YES=0
# Tracks whether a subcommand was explicitly invoked (prevents interactive core prompt when a subcommand is present)
SUBCOMMAND_USED=0

# Repository root (used by functions that delegate to repo scripts)
repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Temporary file tracking for safe cleanup
TMP_FILES=()
mktemp_file() {
    local tmpl="${1:-tmp.XXXXXXXX}"
    local f
    f="$(mktemp -t "$tmpl")" || return 1
    # track for cleanup
    TMP_FILES+=("$f")
    printf '%s' "$f"
}
cleanup_tmp_files() {
    for f in "${TMP_FILES[@]:-}"; do
        [ -n "$f" ] && rm -rf "$f"
    done
}
trap cleanup_tmp_files EXIT

print_usage() {
    cat <<'EOF'
Usage: $(basename "$0") [options] OR $(basename "$0") <subcommand> [options]

Subcommands:
  core                 Install recommended set (Brewfile, hererocks, npm)
  brew [--update] [--commit] [--dry-run]  Run brew bundle (delegates to scripts/brew-install.sh); --update appends missing packages; --commit commits Brewfile; --dry-run prints actions without executing
  pynvim               Install pynvim (pip --user)
  hererocks            Bootstrap hererocks (Lua 5.1)
  npm                  Install npm global language servers (delegates to npm/install.sh)
  config --press-and-hold     Configure macOS: disable press-and-hold (enable key repeat)

Note: invoking a subcommand (e.g., `config` or `brew`) will not trigger the interactive "Install core set" prompt; subcommands are treated as explicit actions.
  --yes, -y            Assume yes for prompts
  --help               Show this help

Examples:
  $(basename "$0") core
  $(basename "$0") brew --update --commit
  $(basename "$0") pynvim
  $(basename "$0") config --press-and-hold
  # Fully non-interactive bootstrap (installs core set without prompts)
  $(basename "$0") --all --yes
EOF
}     

install_pip_user() {
    local pkg="$1"
    if ! command -v python3 >/dev/null 2>&1; then
        echo "python3 not found; cannot install Python package $pkg"
        return 1
    fi

    echo "Installing Python package $pkg (pip --user)..."
    # Try user install first and capture output without failing the script (PEP 668 returns non-zero)
    set +e
    output="$(python3 -m pip install --user "$pkg" 2>&1)"
    rc=$?
    set -e
    if [ $rc -eq 0 ]; then
        echo "$pkg installed via pip --user"
        return 0
    fi

    # If pip failed due to PEP 668 (externally-managed env), create a venv fallback
    if echo "$output" | grep -qiE 'externally-managed-environment|externally managed|PEP 668'; then
        echo "Detected an externally-managed Python environment (PEP 668); creating a virtualenv and installing $pkg there..."
        venv_base="${XDG_DATA_HOME:-$HOME/.local/share}/venvs"
        venv_dir="$venv_base/$pkg"
        mkdir -p "$venv_base"
        if [ ! -d "$venv_dir" ]; then
            if ! python3 -m venv "$venv_dir"; then
                echo "Failed to create venv at $venv_dir" >&2
                return 1
            fi
            # Ensure pip is up-to-date in the venv
            "$venv_dir/bin/python" -m pip install --upgrade pip setuptools >/dev/null 2>&1 || true
        fi

        if "$venv_dir/bin/python" -m pip install "$pkg"; then
            echo "$pkg installed into virtualenv at $venv_dir"
            # Helpful message for pynvim users to configure Neovim
            if [ "$pkg" = "pynvim" ]; then
                echo "To use this Python with Neovim, set in your config:"
                echo "  lua: vim.g.python3_host_prog = '$venv_dir/bin/python'"
                echo "  vimscript: let g:python3_host_prog = '$venv_dir/bin/python'"
            fi
            return 0
        else
            echo "Failed to install $pkg into venv at $venv_dir" >&2
            return 1
        fi
    fi

    # Otherwise return the original pip error
    echo "$output" >&2
    return $rc
}

bootstrap_hererocks() {
    if ! command -v python3 >/dev/null 2>&1; then
        echo "python3 not found; please install Python 3 to bootstrap hererocks"
        return 1
    fi

    # If hererocks is already importable, skip install step
    if python3 -c "import hererocks" >/dev/null 2>&1; then
        echo "hererocks already available in Python environment"
    else
        # Prefer using pipx (provides a CLI shim in PATH)
        if command -v pipx >/dev/null 2>&1; then
            echo "Installing hererocks via pipx..."
            if pipx install hererocks; then
                echo "hererocks installed via pipx"
            else
                echo "Failed to install hererocks via pipx"
            fi
        else
            # pipx not found: show instructions and offer a temporary venv fallback
            echo "pipx not found. To install pipx manually, run:"
            echo "  brew install pipx"
            echo "  pipx install hererocks"
            if [ $ASSUME_YES -eq 1 ]; then
                answer2=y
            else
                read -r -p "Install hererocks now into a temporary venv and run bootstrap? [Y/n] " answer2
            fi
            case "$answer2" in
                [Nn]*) echo "Skipping hererocks installation; you can install pipx manually and re-run this script"; return 1 ;;
                *)
                    tmpdir="$(mktemp -d)"
                    echo "Creating temporary venv at $tmpdir/venv"
                    python3 -m venv "$tmpdir/venv"
                    # shellcheck disable=SC1091
                    . "$tmpdir/venv/bin/activate"
                    # Use the venv python to install robustly
                    "$tmpdir/venv/bin/python" -m pip install --upgrade pip setuptools >/dev/null 2>&1 || true
                    "$tmpdir/venv/bin/python" -m pip install hererocks >/dev/null 2>&1 || true
                    if "$tmpdir/venv/bin/python" -c "import hererocks" >/dev/null 2>&1; then
                        echo "hererocks installed into temporary venv"
                    else
                        echo "Failed to install hererocks in temporary venv"
                        deactivate 2>/dev/null || true
                        rm -rf "$tmpdir"
                        return 1
                    fi
                    deactivate 2>/dev/null || true
                    rm -rf "$tmpdir"
                    ;;
            esac
        fi
    fi

    # Run bootstrap if HEREROCKS_DIR not present
    if [ ! -d "$HEREROCKS_DIR" ]; then
        echo "Bootstrapping hererocks Lua 5.1 at $HEREROCKS_DIR..."
        # Prefer 'hererocks' CLI if available (pipx provides a shim), else fall back to module
        if command -v hererocks >/dev/null 2>&1; then
            hererocks "$HEREROCKS_DIR" --lua=5.1
        elif python3 -c "import hererocks" >/dev/null 2>&1; then
            python3 -m hererocks "$HEREROCKS_DIR" --lua=5.1
        elif command -v pipx >/dev/null 2>&1; then
            # Use pipx run to execute hererocks in an ephemeral environment
            pipx run hererocks "$HEREROCKS_DIR" --lua=5.1 || true
        else
            # As a last resort, install into user site and attempt module invocation
            if python3 -m pip install --user hererocks >/dev/null 2>&1; then
                python3 -m hererocks "$HEREROCKS_DIR" --lua=5.1 || true
            else
                echo "Failed to find a way to run hererocks to bootstrap; please install hererocks or pipx and re-run."
                return 1
            fi
        fi
    else
        echo "hererocks environment already exists at $HEREROCKS_DIR"
    fi
}

install_npm_globals() {
    # Delegate to npm/install.sh if present; keep backward-compatible fallback
    if [ -x "$repo_root/npm/install.sh" ] || [ -f "$repo_root/npm/install.sh" ]; then
        echo "Delegating npm global install to $repo_root/npm/install.sh"
        # Preserve ASSUME_YES by passing --yes when appropriate
        if [ "${ASSUME_YES:-0}" -eq 1 ]; then
            bash "$repo_root/npm/install.sh" --yes "$@"
        else
            bash "$repo_root/npm/install.sh" "$@"
        fi
        return $?
    fi

    # Fallback: legacy behavior - install a small set of npm globals if npm is available
    npm_globals=("bash-language-server" "typescript-language-server" "typescript")
    if command -v npm >/dev/null 2>&1; then
        echo "Installing npm global packages: ${npm_globals[*]}"
        if [ "${ASSUME_YES:-0}" -eq 1 ]; then
            npm i -g "${npm_globals[@]}"
        else
            read -r -p "Install npm global packages (${npm_globals[*]})? [Y/n] " ans
            case "$ans" in
                [Nn]*) echo "Skipping npm globals" ;;
                *) npm i -g "${npm_globals[@]}" ;;
            esac
        fi
    else
        echo "npm not found; skip installing npm global packages. Install Node.js or run npm installs manually."
    fi
}

# parse args
# Support both subcommand-style: 'install <subcommand> [options]' and legacy flags
if [ "$#" -gt 0 ] && [[ "$1" != -* ]]; then
    # Treat first arg as a subcommand
    SUBCOMMAND_USED=1
    case "$1" in
        core)
            DO_BREWFILE=1; DO_HEREROCKS=1; DO_NPM=1; shift
            ;;
        brew)
            DO_BREWFILE=1; shift
            # Parse brew-specific options
            while [ "$#" -gt 0 ] && [[ "$1" == --* ]]; do
                case "$1" in
                    --update|--update-brewfile) DO_UPDATE_BREWFILE=1; shift ;;
                    --commit|--commit-brewfile) DO_COMMIT_BREWFILE=1; DO_UPDATE_BREWFILE=1; shift ;;
                    --yes|-y) ASSUME_YES=1; shift ;;
                    --help) print_usage; exit 0 ;;
                    *) echo "Unknown brew option: $1"; print_usage; exit 1 ;;
                esac
            done
            ;;
        pynvim)
            DO_PYPNVIM=1; shift ;;
        hererocks)
            DO_HEREROCKS=1; shift ;;
        npm)
            DO_NPM=1; shift ;;
        config)
            shift
            while [ "$#" -gt 0 ] && [[ "$1" == --* ]]; do
                case "$1" in
                    --press-and-hold) DO_CONFIG_PRESS_AND_HOLD=1; shift ;;
                    --help) print_usage; exit 0 ;;
                    *) echo "Unknown config option: $1"; print_usage; exit 1 ;;
                esac
            done
            ;;
        *)
            echo "Unknown subcommand: $1"; print_usage; exit 1 ;;
    esac
else
    # Legacy flag-style parsing
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --all)
                DO_BREWFILE=1; DO_HEREROCKS=1; DO_NPM=1; shift ;;

            --hererocks)
                DO_HEREROCKS=1; shift ;;
            --pynvim)
                DO_PYPNVIM=1; shift ;;
            --brewfile)
                DO_BREWFILE=1; shift ;;
            --update-brewfile)
                DO_UPDATE_BREWFILE=1; shift ;; 
            --commit-brewfile)
            # Commit implies updating the Brewfile (append missing packages)
                DO_COMMIT_BREWFILE=1; DO_UPDATE_BREWFILE=1; shift ;;
            --npm-globals)
                DO_NPM=1; shift ;;
            --enable-macos-key-repeat)
                DO_CONFIG_PRESS_AND_HOLD=1; shift ;;
            --yes|-y)
                ASSUME_YES=1; shift ;;
            --help)
                print_usage; exit 0 ;;
            *)
                echo "Unknown arg: $1"; print_usage; exit 1 ;;
        esac
    done
fi



# Delegate Brew operations to dedicated script for maintainability
BREWFILE_USED=""
BREW_SCRIPT="$repo_root/scripts/brew-install.sh"
if [ "$DO_BREWFILE" -eq 1 ]; then
    if [ -f "$BREW_SCRIPT" ]; then
        # Build args
        args=()
        [ $DO_UPDATE_BREWFILE -eq 1 ] && args+=(--update)
        [ $DO_COMMIT_BREWFILE -eq 1 ] && args+=(--commit)
        [ $ASSUME_YES -eq 1 ] && args+=(--yes)
        if [ ${#BREW_REQUIRED[@]} -gt 0 ]; then
            args+=("${BREW_REQUIRED[@]}")
        fi

        echo "Delegating brew operations to: $BREW_SCRIPT ${args[*]:-}"
        if ! out="$(bash "$BREW_SCRIPT" "${args[@]:-}" 2>&1)"; then
            printf "%s\n" "$out"
            echo "scripts/brew-install.sh failed" >&2
        else
            printf "%s\n" "$out"
        fi
    else
        echo "Brew helper script not found at $BREW_SCRIPT; skipping Brew operations"
    fi
fi

if [ $DO_HEREROCKS -eq 1 ]; then
    bootstrap_hererocks
fi

if [ $DO_PYPNVIM -eq 1 ]; then
    install_pip_user pynvim
fi

if [ $DO_NPM -eq 1 ]; then
    install_npm_globals
fi



if [ $DO_HEREROCKS -eq 1 ]; then
    echo "  Hererocks env: $HEREROCKS_DIR"
fi
if [ $DO_PYPNVIM -eq 1 ]; then
    echo "  Python: pynvim installed (--user)"
fi

printf "\nVerify by running:\n"
printf "  tree-sitter --version || true\n"
printf "  python3 -c 'import pynvim' && echo 'pynvim OK' || true\n"
printf "  nvim --headless -c 'checkhealth nvim-treesitter' -c q\n"

echo "If Neovim still reports missing luarocks, ensure $HEREROCKS_DIR/bin is in your PATH."

# macOS key-repeat setting: apply only when requested via 'config --press-and-hold' or legacy flag
if [ "${DO_CONFIG_PRESS_AND_HOLD:-0}" -eq 1 ]; then
    if [ "$(uname -s)" = "Darwin" ]; then
        # Inform the user and apply the setting; do not fail the script if 'defaults' fails
        echo "Configuring macOS: disable press-and-hold input (ApplePressAndHoldEnabled=false)"
        defaults write -g ApplePressAndHoldEnabled -bool false || true
    else
        echo "Skipping press-and-hold config: not macOS"
    fi
fi

exit 0

