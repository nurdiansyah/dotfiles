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
	exit 0
else
	echo "Help output did not contain 'Usage:'"
	exit 2
fi
