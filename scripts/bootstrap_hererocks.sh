#!/usr/bin/env bash
set -euo pipefail

# scripts/bootstrap_hererocks.sh
# Optional helper to install hererocks (prefers pipx, falls back to venv)
# Usage: scripts/bootstrap_hererocks.sh [--yes] [--use-pipx] [--use-venv]

ASSUME_YES=0
FORCE_PIPX=0
FORCE_VENV=0

print_usage() {
	cat <<EOF
Usage: $(basename "$0") [options]
Options:
	--yes	Assume yes to prompts (non-interactive)
	--use-pipx	Require using pipx (fail if unavailable)
	--use-venv	Require using venv fallback
	--help	Show this help
EOF
}

while [ "$#" -gt 0 ]; do
	case "$1" in
		--yes)
			ASSUME_YES=1; shift ;;
		--use-pipx)
			FORCE_PIPX=1; shift ;;
		--use-venv)
			FORCE_VENV=1; shift ;;
		--help)
			print_usage; exit 0 ;;
		*)
			echo "Unknown arg: $1"; print_usage; exit 1 ;;
	esac
done

if ! command -v python3 >/dev/null 2>&1; then
	echo "python3 not found; please install Python 3 to bootstrap hererocks"
	exit 1
fi

install_via_pipx() {
	if ! command -v pipx >/dev/null 2>&1; then
		echo "pipx is not available"
		return 1
	fi
	echo "Installing hererocks via pipx..."
	if pipx install hererocks; then
		echo "hererocks installed via pipx"
		return 0
	else
		echo "pipx install hererocks failed"
		return 1
	fi
}

install_via_venv() {
	tmpdir="$(mktemp -d)"
	echo "Creating temporary venv at $tmpdir/venv"
	python3 -m venv "$tmpdir/venv"
	# shellcheck disable=SC1091
	. "$tmpdir/venv/bin/activate"
	pip install --upgrade pip setuptools >/dev/null 2>&1 || true
	pip install hererocks >/dev/null 2>&1 || true
	if python3 -c "import hererocks" >/dev/null 2>&1; then
		echo "hererocks installed into temporary venv"
		deactivate 2>/dev/null || true
		rm -rf "$tmpdir"
		return 0
	else
		deactivate 2>/dev/null || true
		rm -rf "$tmpdir"
		echo "Failed to install hererocks in temporary venv"
		return 1
	fi
}

# If forced to use pipx and it's not available, try to install pipx via brew if --yes
if [ "$FORCE_PIPX" -eq 1 ] && ! command -v pipx >/dev/null 2>&1; then
	if [ "$ASSUME_YES" -eq 1 ]; then
		if command -v brew >/dev/null 2>&1; then
			echo "Installing pipx via brew..."
			brew install pipx
			pipx ensurepath >/dev/null 2>&1 || true
		else
			echo "Homebrew not found; cannot auto-install pipx"
			exit 1
		fi
	else
		echo "pipx is not available and not allowed to install. Use --help for options."
		exit 1
	fi
fi

# Try pipx first unless forced to use venv
if [ "$FORCE_VENV" -eq 1 ]; then
	install_via_venv || exit 1
else
	if install_via_pipx; then
		echo "Installed via pipx"
	else
		if [ "$ASSUME_YES" -eq 1 ]; then
			answer=y
		else
			read -r -p "pipx is not available or failed. Use temporary venv fallback? [Y/n] " answer
		fi
		case "$answer" in
			[Nn]*) echo "Aborting"; exit 1 ;;
			*) install_via_venv || exit 1 ;;
		esac
	fi
fi

echo "To bootstrap hererocks tree run: python3 -m hererocks <target_dir> --lua=5.1"
exit 0
