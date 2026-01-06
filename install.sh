#!/usr/bin/env bash
set -euo pipefail

# install.sh
# Install selected external dependencies (macOS/Homebrew), with flags or interactive mode.

HEREROCKS_DIR="$HOME/.local/share/nvim/lazy-rocks/hererocks"

BREW_REQUIRED=()
DO_HEREROCKS=0
DO_PYPNVIM=0
DO_BREWFILE=0
ASSUME_YES=0

print_usage() {
	cat <<EOF
Usage: $0 [options]
Options:
	--all           Install recommended default set (fd, git, tree-sitter, luarocks, hererocks)
	--fd            Install fd (brew: fd)
	--git           Install git
	--tree-sitter   Install tree-sitter
	--luarocks      Install luarocks (brew)
	--hererocks     Bootstrap hererocks (Lua 5.1 environment)
	--pynvim        Install Python pynvim (pip user)
	--brewfile      Install packages from the repository Brewfile (runs `brew bundle --file=Brewfile`)
	--yes, -y       Assume yes for prompts
	--help          Show this help
EOF
}

add_brew() {
	BREW_REQUIRED+=("$1")
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
	if [ ! -f "Brewfile" ]; then
		echo "Brewfile not found in the repo root; create or run `brew bundle --file=Brewfile` manually."
		return 1
	fi
	if ! command -v brew >/dev/null 2>&1; then
		echo "Homebrew not found; please install Homebrew first."
		return 1
	fi

	echo "Running: brew bundle --file=Brewfile"
	brew bundle --file=Brewfile || true
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
			add_brew ripgrep
			add_brew fd
			add_brew git
			add_brew tree-sitter
			add_brew luarocks
			DO_HEREROCKS=1
			shift
			;;
		--fd)
			add_brew fd; shift ;;
		--git)
			add_brew git; shift ;;
		--tree-sitter)
			add_brew tree-sitter; shift ;;
		--luarocks)
			add_brew luarocks; shift ;;
		--hererocks)
			DO_HEREROCKS=1; shift ;;
		--pynvim)
			DO_PYPNVIM=1; shift ;;
		--brewfile)
			DO_BREWFILE=1; shift ;;
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
	echo "No options provided. Install core set? (fd, git, tree-sitter, luarocks, hererocks)"
	if [ $ASSUME_YES -eq 1 ]; then
		answer=y
	else
		read -r -p "Install core packages now? [Y/n] " answer
	fi
	case "$answer" in
		[Nn]*) echo "Aborting install."; exit 0 ;;
		*)
			add_brew fd
			add_brew git
			add_brew tree-sitter
			add_brew luarocks
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

for pkg in "${BREW_REQUIRED[@]:-}"; do
	case "$pkg" in
		fd) install_brew fd ;;
		ripgrep) install_brew ripgrep ;;
		git) install_brew git ;;
		tree-sitter) install_brew tree-sitter ;;
		luarocks) install_brew luarocks ;;
		*) install_brew "$pkg" ;;
	esac
done

if [ $DO_HEREROCKS -eq 1 ]; then
	bootstrap_hererocks
fi

if [ $DO_PYPNVIM -eq 1 ]; then
	echo "Installing pynvim (pip --user)..."
	python3 -m pip install --user pynvim
fi

echo "\nSummary:"
echo "  Brew packages installed: ${BREW_REQUIRED[*]:-(none)}"
if [ $DO_HEREROCKS -eq 1 ]; then
	echo "  Hererocks env: $HEREROCKS_DIR"
fi
if [ $DO_PYPNVIM -eq 1 ]; then
	echo "  Python: pynvim installed (--user)"
fi

echo "\nVerify by running:" 
echo "  tree-sitter --version || true"
echo "  luarocks --version || true"
echo "  python3 -c 'import pynvim' && echo 'pynvim OK' || true"
echo "  nvim --headless -c 'checkhealth nvim-treesitter' -c q"

echo "If Neovim still reports missing luarocks, ensure $HEREROCKS_DIR/bin is in your PATH."

exit 0

exit 0

