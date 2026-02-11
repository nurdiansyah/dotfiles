#!/usr/bin/env bash
# Quick smoke-test for Zsh Znap helper (non-destructive, no network ops)
# Usage:
#   ./scripts/test_zsh_znap_smoke.sh
# Exits non-zero on failure.

set -euo pipefail
PROG=$(basename "$0")
QUIET=false
FAILED=false

ok() { [ "$QUIET" = true ] || echo "[OK]    $1"; }
warn() { [ "$QUIET" = true ] || echo "[WARN]  $1"; }
fail() { echo "[FAIL]  $1" >&2; FAILED=true; }

if [ "$#" -gt 0 ]; then
  case "$1" in
    -q|--quiet) QUIET=true; shift ;;
    -h|--help)
      cat <<-USAGE
Usage: $PROG [--quiet]

Quick smoke-test that verifies the repo's Znap helper function
`zsh_znap_install_plugins` is defined and invokes `znap` in a safe,
stubbed environment (no network clones).

Exit codes:
  0 success
  1 failure
USAGE
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
fi

echo "Zsh/Znap smoke-test — quick checks"

# Check requirements
if ! command -v zsh >/dev/null 2>&1; then
  fail "zsh not found in PATH"
  echo "Summary"
  exit 1
fi

TMPHOME=$(mktemp -d)
TMPPATH=$(mktemp -d)
trap 'rm -rf "$TMPHOME" "$TMPPATH"' EXIT

# Create a no-op znap init file so .zshrc won't attempt to git-clone Znap
mkdir -p "$TMPHOME/.local/znap"
cat > "$TMPHOME/.local/znap/znap.zsh" <<'EOF'
# stub znap init for test
# Keep minimal: do not perform network or change state
true
EOF

# Create a znap stub in PATH that accepts commands and exits 0
cat > "$TMPPATH/znap" <<'EOF'
#!/usr/bin/env bash
# Minimal znap stub for smoke-test
echo "[znap-stub] $@" >&2
case "$1" in
  clone|source|pull|clean|status) exit 0 ;;
  help) echo "stub" ; exit 0 ;;
  *) exit 0 ;;
esac
EOF
chmod +x "$TMPPATH/znap"

# Run zsh in an isolated environment: use TMPHOME as HOME and prepend TMPPATH to PATH.
# Source the repo's zsh/.zshrc and verify the helper runs and prints its summary message.
set +e
OUT=$(HOME="$TMPHOME" PATH="$TMPPATH:$PATH" zsh -i -c 'source "$(pwd)/zsh/.zshrc" && type zsh_znap_install_plugins >/dev/null && zsh_znap_install_plugins' 2>&1)
RC=$?
set -e

if [ $RC -ne 0 ]; then
  echo "$OUT" >&2
  fail "zsh_znap_install_plugins exited non-zero ($RC)"
else
  ok "zsh_znap_install_plugins returned success"
fi

# Check output contains indication of stub invocation and summary message
if echo "$OUT" | grep -q "\[znap-stub\]"; then
  ok "znap stub invoked"
else
  echo "$OUT" >&2
  warn "znap stub not observed in output (maybe znap not called)"
fi

if echo "$OUT" | grep -q "Znap: attempted to install/update plugins"; then
  ok "helper printed summary message"
else
  echo "$OUT" >&2
  fail "helper did not print expected summary message"
fi

# Finish
if [ "$FAILED" = true ]; then
  echo "Summary: one or more checks failed" >&2
  exit 1
else
  echo "Summary: all checks passed"
  exit 0
fi
