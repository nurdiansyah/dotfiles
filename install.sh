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
ASSUME_YES=0

print_usage() {
	cat <<EOF
Usage: $0 [options]
Options:
	--all           Install recommended default set (fd, git, tree-sitter, hererocks)
	--fd            Install fd (brew: fd)
	--git           Install git
	--tree-sitter   Install tree-sitter
	--hererocks     Bootstrap hererocks (Lua 5.1 environment)
	--pynvim        Install Python pynvim (pip user)
	--brewfile      Install packages from the repository Brewfile (runs `brew bundle --file=Brewfile`)
	--update-brewfile  Append missing requested packages to the repository Brewfile (creates backup; no commit)
	--commit-brewfile  Commit appended packages to the repository Brewfile (requires git; creates backup)
	--npm-globals   Install npm global packages (bash/typescript language servers)
	--yes, -y       Assume yes for prompts
	--help          Show this help
EOF
}

add_brew() {
	local pkg="$1"
	# If a Brewfile exists in the repo root, don't add packages that are already declared there
	repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
	if [ -f "$repo_root/Brewfile" ]; then
		# Match either formulae 'brew "name"' or casks 'cask "name"'
		if grep -E '^[[:space:]]*(brew|cask) ' "$repo_root/Brewfile" | sed -E 's/.*"([^\\\"]+)".*/\\1/' | grep -xq -- "$pkg"; then
			echo "Skipping add for '$pkg' because it is declared in $repo_root/Brewfile"
			return
		fi
	fi

	BREW_REQUIRED+=("$pkg")
} 

install_brew() {
	local pkg="$1"
	if command -v brew >/dev/null 2>&1; then
		if brew list "$pkg" >/dev/null 2>&1; then
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
	echo "Installing Python package $pkg (pip --user)..."
	python3 -m pip install --user "$pkg"
}

bootstrap_hererocks() {
	if ! python3 -c "import hererocks" >/dev/null 2>&1; then
		echo "Installing hererocks (pip --user)..."
		python3 -m pip install --user hererocks
	fi

	if [ ! -d "$HEREROCKS_DIR" ]; then
		echo "Bootstrapping hererocks Lua 5.1 at $HEREROCKS_DIR..."
		python3 -m hererocks "$HEREROCKS_DIR" --lua=5.1
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
	# Install npm-based language servers used by the repo if node/npm available
	npm_globals=("bash-language-server" "typescript-language-server" "typescript")
	if command -v npm >/dev/null 2>&1; then
		echo "Installing npm global packages: ${npm_globals[*]}"
		if [ $ASSUME_YES -eq 1 ]; then
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
while [ "$#" -gt 0 ]; do
	case "$1" in
		--all)
			# Use the repo Brewfile to install core packages instead of listing them here
			DO_BREWFILE=1
			DO_HEREROCKS=1
			DO_NPM=1
			shift
			;;

		--hererocks)
			DO_HEREROCKS=1; shift ;;
		--pynvim)
			DO_PYPNVIM=1; shift ;;
		--brewfile)
			DO_BREWFILE=1; shift ;;
		--update-brewfile)
			DO_UPDATE_BREWFILE=1; shift ;;
		--commit-brewfile)
			DO_COMMIT_BREWFILE=1; shift ;;
		--npm-globals)
			DO_NPM=1; shift ;;
		--yes|-y)
			ASSUME_YES=1; shift ;;
		--help)
			print_usage; exit 0 ;;
		*)
			echo "Unknown arg: $1"; print_usage; exit 1 ;;
	esac
done

# If nothing selected, ask interactively
if [ ${#BREW_REQUIRED[@]} -eq 0 ] && [ $DO_HEREROCKS -eq 0 ] && [ $DO_PYPNVIM -eq 0 ]; then
	echo "No options provided. Install core set? (fd, git, tree-sitter, hererocks)"
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

# Deduplicate BREW_REQUIRED
if [ ${#BREW_REQUIRED[@]} -gt 0 ]; then
	mapfile -t BREW_REQUIRED < <(printf "%s\n" "${BREW_REQUIRED[@]}" | awk '!seen[$0]++')
fi

# Prefer using Brewfile for Homebrew installs. If requested packages exist, generate
# a temporary Brewfile (based on repo Brewfile when present) and run `brew bundle`.
repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
BREWFILE_USED=""
if [ "$DO_BREWFILE" -eq 1 ] || [ ${#BREW_REQUIRED[@]} -gt 0 ]; then
	if [ -f "$repo_root/Brewfile" ]; then
		# Repo Brewfile exists
		if [ ${#BREW_REQUIRED[@]} -eq 0 ]; then
			echo "Using repository Brewfile at $repo_root/Brewfile"
			brew bundle --file="$repo_root/Brewfile" || true
			BREWFILE_USED="$repo_root/Brewfile"
		else
			# If requested, append missing packages to the repo Brewfile (creates a backup)
			missing_pkgs=()
			for pkg in "${BREW_REQUIRED[@]}"; do
				if ! grep -E '^[[:space:]]*(brew|cask) ' "$repo_root/Brewfile" | sed -E 's/.*"([^\"]+)".*/\1/' | grep -xq -- "$pkg"; then
					missing_pkgs+=("$pkg")
				fi
			done

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
					if git -C "$repo_root" add Brewfile && git -C "$repo_root" commit -m "chore(brewfile): add ${APPENDED_PKGS[*]}" >/dev/null 2>&1; then
						BREWFILE_COMMIT=$(git -C "$repo_root" rev-parse --short HEAD 2>/dev/null || true)
						echo "Committed Brewfile changes: $BREWFILE_COMMIT"
					else
						echo "Failed to commit Brewfile changes; leaving backup at $backup_path"
					fi
				else
					echo "Git not found; cannot commit Brewfile automatically."
				fi
			fi
			# run bundle on the updated repo Brewfile
			echo "Running: brew bundle --file=$repo_root/Brewfile"
			brew bundle --file="$repo_root/Brewfile" || true
			BREWFILE_USED="$repo_root/Brewfile (updated)"
			else
				# Create temp Brewfile from repo Brewfile and append missing entries
				tmp_brewfile="$(mktemp)"
				cp "$repo_root/Brewfile" "$tmp_brewfile"
				for pkg in "${BREW_REQUIRED[@]}"; do
					if ! grep -E '^[[:space:]]*(brew|cask) ' "$tmp_brewfile" | sed -E 's/.*"([^\"]+)".*/\1/' | grep -xq -- "$pkg"; then
						echo "brew \"$pkg\"" >> "$tmp_brewfile"
					fi
				done
				echo "Running: brew bundle --file=$tmp_brewfile"
				brew bundle --file="$tmp_brewfile" || true
				BREWFILE_USED="$tmp_brewfile (generated from repo Brewfile)"
				rm -f "$tmp_brewfile"
			fi
		fi
	else
		# No repo Brewfile — create temp Brewfile containing requested packages
		if [ ${#BREW_REQUIRED[@]} -gt 0 ]; then
			tmp_brewfile="$(mktemp)"
			for pkg in "${BREW_REQUIRED[@]}"; do
				echo "brew \"$pkg\"" >> "$tmp_brewfile"
			done
			echo "Running: brew bundle --file=$tmp_brewfile"
			brew bundle --file="$tmp_brewfile" || true
			BREWFILE_USED="$tmp_brewfile (generated)"
			rm -f "$tmp_brewfile"
		fi
	fi
fi

# If a Brewfile run was not performed, fall back to per-package installs
if [ -z "$BREWFILE_USED" ]; then
	for pkg in "${BREW_REQUIRED[@]:-}"; do
		case "$pkg" in
			fd) install_brew fd ;;
			ripgrep) install_brew ripgrep ;;
			git) install_brew git ;;
			tree-sitter) install_brew tree-sitter ;;
			*) install_brew "$pkg" ;;
		esac
done
fi

if [ $DO_HEREROCKS -eq 1 ]; then
	bootstrap_hererocks
fi

if [ $DO_PYPNVIM -eq 1 ]; then
	echo "Installing pynvim (pip --user)..."
	python3 -m pip install --user pynvim
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

exit 0

