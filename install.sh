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

Legacy (flag-style) options:
  --all                Same as 'core'
  --hererocks          Bootstrap hererocks (Lua 5.1)
  --pynvim             Install pynvim (pip --user)
  --brewfile           Run: brew bundle --file=Brewfile (repo root)
  --update-brewfile    Append missing packages to repo Brewfile (creates backup)
  --commit-brewfile    Commit appended Brewfile changes (requires git)
  --npm-globals        Install npm global language servers
  --enable-macos-key-repeat  Enable macOS key repeat (alias for config --press-and-hold)
  --yes, -y            Assume yes for prompts
  --help               Show this help

Examples:
  $(basename "$0") core
  $(basename "$0") brew --update --commit
  $(basename "$0") pynvim
  $(basename "$0") config --press-and-hold
EOF
}     

add_brew() {
	local pkg="$1"
	# If a Brewfile exists in the repo root, don't add packages that are already declared there
	repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
	if [ -f "$repo_root/Brewfile" ]; then
		# Match either formulae 'brew "name"' or casks 'cask "name"' (handles single/double/unquoted names)
		if grep -E '^[[:space:]]*(brew|cask) ' "$repo_root/Brewfile" | sed -E 's/^[[:space:]]*(brew|cask)[[:space:]]+['\''"]?([^'\''"[:space:],]+).*/\2/' | grep -xq -- "$pkg"; then
			echo "Skipping add for '$pkg' because it is declared in $repo_root/Brewfile"
			return
		fi
	fi

	BREW_REQUIRED+=("$pkg")
} 

install_brew() {
	local pkg="$1"
	if command -v brew >/dev/null 2>&1; then
		if brew ls --versions "$pkg" >/dev/null 2>&1; then
			echo "$pkg already installed (brew)"
		else
			echo "Installing $pkg via brew..."
			brew install "$pkg"
		fi
	else
		echo "Homebrew not found; please install Homebrew or install $pkg manually."
		return 1
	fi
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

install_brewfile() {
	repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
	if [ ! -f "$repo_root/Brewfile" ]; then
		echo "Brewfile not found in the repository root ($repo_root); create or run \`brew bundle --file=Brewfile\` manually."
		return 1
	fi
	if ! command -v brew >/dev/null 2>&1; then
		echo "Homebrew not found; please install Homebrew first."
		return 1
	fi

	echo "Running: brew bundle --file=$repo_root/Brewfile"
	brew bundle --file="$repo_root/Brewfile" || true
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

# If nothing selected, ask interactively
if [ ${#BREW_REQUIRED[@]} -eq 0 ] && [ $DO_HEREROCKS -eq 0 ] && [ $DO_PYPNVIM -eq 0 ]; then
	echo "No options provided. Install core set? (hererocks and Brewfile packages)"
	if [ $ASSUME_YES -eq 1 ]; then
		answer=y
	else
		read -r -p "Install core packages now? [Y/n] " answer
	fi
	case "$answer" in
		[Nn]*) echo "Aborting install."; exit 0 ;;
		*)
			# Use Brewfile for core packages; still bootstrap hererocks and pynvim as before
			DO_BREWFILE=1
			DO_HEREROCKS=1
			DO_PYPNVIM=1
			;;
	esac
fi

echo "Updating Homebrew..."
if command -v brew >/dev/null 2>&1; then
	brew update || true
fi

# Deduplicate BREW_REQUIRED (portable across macOS bash 3.2 and later)
if [ ${#BREW_REQUIRED[@]} -gt 0 ]; then
	unique_pkgs=()
	for pkg in "${BREW_REQUIRED[@]}"; do
		found=0
		for u in "${unique_pkgs[@]}"; do
			[ "$pkg" = "$u" ] && { found=1; break; }
		done
		if [ $found -eq 0 ]; then
			unique_pkgs+=("$pkg")
		fi
	done
	BREW_REQUIRED=("${unique_pkgs[@]}")
fi

# Delegate Brew operations to dedicated script for maintainability
repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
BREWFILE_USED=""
BREW_SCRIPT="$repo_root/scripts/brew-install.sh"
if [ "$DO_BREWFILE" -eq 1 ] || [ ${#BREW_REQUIRED[@]} -gt 0 ]; then
	if [ -x "$BREW_SCRIPT" ]; then
		# Build args
		args=()
		[ $DO_UPDATE_BREWFILE -eq 1 ] && args+=(--update)
		[ $DO_COMMIT_BREWFILE -eq 1 ] && args+=(--commit)
		[ $ASSUME_YES -eq 1 ] && args+=(--yes)
		if [ ${#BREW_REQUIRED[@]} -gt 0 ]; then
			args+=("${BREW_REQUIRED[@]}")
		fi

		echo "Delegating brew operations to: $BREW_SCRIPT ${args[*]}"
		out="$("$BREW_SCRIPT" "${args[@]}" 2>&1)" || true
		# Forward output for visibility
		printf "%s\n" "$out"
		# Parse machine-readable markers
		BREWFILE_USED=$(printf "%s\n" "$out" | awk -F'BREW-INFO: ' '/BREW-INFO: USED/ {print $2; exit}')
		APPENDED_PKGS=$(printf "%s\n" "$out" | awk -F'BREW-INFO: ' '/BREW-INFO: APPENDED/ {print $2; exit}')
		backup_path=$(printf "%s\n" "$out" | awk -F'BREW-INFO: ' '/BREW-INFO: BACKUP/ {print $2; exit}')
		BREWFILE_COMMIT=$(printf "%s\n" "$out" | awk -F'BREW-INFO: ' '/BREW-INFO: COMMIT/ {print $2; exit}')
	else
		echo "Brew script not found at $BREW_SCRIPT; falling back to in-script behavior"
		if [ -f "$repo_root/Brewfile" ]; then
		# Repo Brewfile exists
		if [ ${#BREW_REQUIRED[@]} -eq 0 ]; then
			if command -v brew >/dev/null 2>&1; then
				echo "Using repository Brewfile at $repo_root/Brewfile"
				brew bundle --file="$repo_root/Brewfile" || true
				BREWFILE_USED="$repo_root/Brewfile"
				# If user asked to commit but no packages were requested, commit Brewfile if it has local changes
				if [ $DO_COMMIT_BREWFILE -eq 1 ]; then
					if command -v git >/dev/null 2>&1; then
						# Check for any changes affecting Brewfile
						if git -C "$repo_root" status --porcelain --untracked-files=normal | grep -q "Brewfile"; then
							git -C "$repo_root" add Brewfile >/dev/null 2>&1 || true
						# Try to extract added package names from the Brewfile diff for a clearer commit message
						# Extract added package names from the diff using perl (portable on macOS)
					changed_pkgs="$(git -C "$repo_root" diff --no-color --unified=0 Brewfile 2>/dev/null \
						| perl -ne "if (/^\\+.*?brew\\s+[\\\"']?([^\\\"'\\s,]+)/) { print \"\\\$1\\n\" }" \
						| uniq | tr '\n' ' ' | sed 's/ $//')"
						if [ -n "$changed_pkgs" ]; then
							commit_msg="chore(brewfile): update ($changed_pkgs)"
						else
							commit_msg="chore(brewfile): update Brewfile"
						fi
						if git -C "$repo_root" commit -m "$commit_msg"; then
								BREWFILE_COMMIT=$(git -C "$repo_root" rev-parse --short HEAD 2>/dev/null || true)
								echo "Committed Brewfile changes: $BREWFILE_COMMIT"
							else
								echo "Failed to commit Brewfile changes; please commit manually in $repo_root"
								git -C "$repo_root" status --porcelain --untracked-files=normal | sed 's/^/  /' || true
							fi
						else
							echo "No changes to Brewfile to commit."
						fi
					else
						echo "Git not found; cannot commit Brewfile automatically."
					fi
				fi
			else
				echo "Homebrew not found; please install Homebrew to run 'brew bundle --file=$repo_root/Brewfile' or run it manually."
			fi
		else
			# If requested, append missing packages to the repo Brewfile (creates a backup)
			missing_pkgs=()
			for pkg in "${BREW_REQUIRED[@]}"; do
				if ! grep -E '^[[:space:]]*(brew|cask) ' "$repo_root/Brewfile" | sed -E 's/^[[:space:]]*(brew|cask)[[:space:]]+['\''"]?([^'\''"[:space:],]+).*/\2/' | grep -xq -- "$pkg"; then
					missing_pkgs+=("$pkg")
				fi
			done

			# If user asked to commit but nothing needs appending, warn and continue
		if [ ${#missing_pkgs[@]} -eq 0 ] && [ $DO_COMMIT_BREWFILE -eq 1 ]; then
			echo "No missing packages to append; nothing to commit."
		fi
		if [ ${#missing_pkgs[@]} -gt 0 ] && [ $DO_UPDATE_BREWFILE -eq 1 ]; then
				backup_path="$repo_root/Brewfile.bak.$(date -u +%Y%m%dT%H%M%SZ)"
cp "$repo_root/Brewfile" "$backup_path"
			# Inform the user about the backup and how to restore it if necessary
			echo "Created backup of existing Brewfile at: $backup_path"
			echo "Restore with: mv \"$backup_path\" \"$repo_root/Brewfile\""
			for pkg in "${missing_pkgs[@]}"; do
					echo "brew \"$pkg\"" >> "$repo_root/Brewfile"
				done
				echo "Appended ${#missing_pkgs[@]} packages to $repo_root/Brewfile (backup: $backup_path)"
			APPENDED_PKGS=("${missing_pkgs[@]}")
			# Optionally commit the change to the repo Brewfile
			if [ $DO_COMMIT_BREWFILE -eq 1 ]; then
				if command -v git >/dev/null 2>&1; then
					# Stage Brewfile first
				if git -C "$repo_root" add Brewfile >/dev/null 2>&1; then
					# Attempt commit (show error if it fails)
					if git -C "$repo_root" commit -m "chore(brewfile): add ${APPENDED_PKGS[*]}"; then
						BREWFILE_COMMIT=$(git -C "$repo_root" rev-parse --short HEAD 2>/dev/null || true)
						echo "Committed Brewfile changes: $BREWFILE_COMMIT"
					else
						echo "Failed to commit Brewfile changes; please commit manually in $repo_root"
						git -C "$repo_root" status --porcelain --untracked-files=normal | sed 's/^/  /' || true
					fi
				else
					echo "Failed to stage Brewfile; please check repository state in $repo_root"
					git -C "$repo_root" status --porcelain --untracked-files=normal | sed 's/^/  /' || true
				fi
			else
				echo "Git not found; cannot commit Brewfile automatically."
			fi
		fi
			# run bundle on the updated repo Brewfile
			echo "Running: brew bundle --file=$repo_root/Brewfile"
			if command -v brew >/dev/null 2>&1; then
				brew bundle --file="$repo_root/Brewfile" || true
				BREWFILE_USED="$repo_root/Brewfile (updated)"
			else
				echo "Homebrew not found; please install Homebrew to run 'brew bundle --file=$repo_root/Brewfile' or run it manually."
			fi
			else
# Create temp Brewfile from repo Brewfile and append missing entries (portable mktemp, tracked cleanup)
				tmp_brewfile="$(mktemp_file brewfile.XXXXXXXX)"
				cp "$repo_root/Brewfile" "$tmp_brewfile"
			for pkg in "${BREW_REQUIRED[@]}"; do
				if ! grep -E '^[[:space:]]*(brew|cask) ' "$tmp_brewfile" | sed -E 's/^[[:space:]]*(brew|cask)[[:space:]]+['\''"]?([^'\''"[:space:],]+).*/\2/' | grep -xq -- "$pkg"; then
					echo "brew \"$pkg\"" >> "$tmp_brewfile"
				fi
			done
			echo "Running: brew bundle --file=$tmp_brewfile"
			if command -v brew >/dev/null 2>&1; then
				brew bundle --file="$tmp_brewfile" || true
				BREWFILE_USED="$tmp_brewfile (generated from repo Brewfile)"
			else
				echo "Homebrew not found; please install Homebrew to run 'brew bundle --file=$tmp_brewfile' or run it manually."
			fi
			fi
		fi
	else
		# No repo Brewfile — create temp Brewfile containing requested packages
		if [ ${#BREW_REQUIRED[@]} -gt 0 ]; then
			tmp_brewfile="$(mktemp_file brewfile.XXXXXXXX)"
			for pkg in "${BREW_REQUIRED[@]}"; do
				echo "brew \"$pkg\"" >> "$tmp_brewfile"
			done
			echo "Running: brew bundle --file=$tmp_brewfile"
			if command -v brew >/dev/null 2>&1; then
				brew bundle --file="$tmp_brewfile" || true
				BREWFILE_USED="$tmp_brewfile (generated)"
			else
				echo "Homebrew not found; please install Homebrew to run 'brew bundle --file=$tmp_brewfile' or run it manually."
			fi
		fi
	fi
fi
fi

# If a Brewfile run was not performed, fall back to per-package installs
if [ -z "$BREWFILE_USED" ]; then
	for pkg in "${BREW_REQUIRED[@]:-}"; do
		case "$pkg" in
			*) install_brew "$pkg" ;;
		esac
done
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



printf "\nSummary:\n"
printf "  Brew packages installed: %s\n" "${BREW_REQUIRED[*]:-(none)}"
if [ -n "${BREWFILE_USED:-}" ]; then
	echo "  Brewfile used: $BREWFILE_USED"
	if [ -n "${APPENDED_PKGS:-}" ]; then
		echo "  Brewfile appended: ${APPENDED_PKGS[*]}"
		if [ -n "${backup_path:-}" ]; then
			echo "  Brewfile backup: $backup_path"
		fi
		if [ -n "${BREWFILE_COMMIT:-}" ]; then
			echo "  Brewfile commit: $BREWFILE_COMMIT"
		fi
	fi
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

