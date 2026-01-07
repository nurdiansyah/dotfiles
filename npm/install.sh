#!/usr/bin/env bash
set -euo pipefail

# wrapper to call the real implementation
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# pass through flags to the implementation
bash "$SCRIPT_DIR/install-npm-globals.sh" "$@"
