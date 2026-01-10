#!/usr/bin/env bash
set -euo pipefail

# Quick local test helper: confirms the bootstrap script prints usage/help and is syntactically valid
SCRIPT="scripts/bootstrap_hererocks.sh"

if [ ! -f "$SCRIPT" ]; then
	echo "$SCRIPT not found"; exit 1
fi

# Ensure executable
chmod +x "$SCRIPT"

# Syntax check
bash -n "$SCRIPT"

echo "Syntax check passed for $SCRIPT"

# Run help and assert it contains 'Usage:'
if "$SCRIPT" --help | grep -q "Usage:"; then
	echo "Help output present"
else
	echo "Help output did not contain 'Usage:'"
	exit 2
fi

# Smoke test for brew-install.sh (dry-run)
BREW_SCRIPT="scripts/brew-install.sh"
if [ -f "$BREW_SCRIPT" ]; then
	chmod +x "$BREW_SCRIPT"
	# Use dry-run to avoid touching the system
	if "$BREW_SCRIPT" --dry-run git curl | grep -q "BREW-INFO: USED"; then
		echo "brew-install dry-run smoke test passed"
	else
		echo "brew-install dry-run did not emit expected markers"
		exit 3
	fi
else
	echo "$BREW_SCRIPT not found; skipping brew-install smoke test"
fi

# Regression test: ensure 'config' subcommand does not trigger the core-install prompt
if ./install.sh config 2>&1 | grep -q "No options provided"; then
	echo "config subcommand incorrectly triggers core-install prompt"
	exit 4
else
	echo "config subcommand did not trigger core prompt (OK)"
fi

exit 0
