#!/usr/bin/env bash
set -euo pipefail

# install-kanata-cmd-allowed.sh
# Download and install the latest kanata macOS 'cmd_allowed' binary for your arch.
# - Uses GitHub Releases API and prefers the newest release containing the desired asset.
# - Verifies SHA256 from the release body if present.
# - Backs up existing /usr/local/bin/kanata to /usr/local/bin/kanata.bak

REPO="jtroo/kanata"
API="https://api.github.com/repos/$REPO/releases"
TMPDIR="/tmp/kanata_install.$$"
INSTALL_PATH="/usr/local/bin/kanata"

usage(){
  cat <<EOF
Usage: $0 [--yes] [--dry-run] [--tag <tag>]

Options:
  --yes            Non-interactive, install without prompt
  --dry-run        Download + verify but do NOT install the binary
  --tag <tag>      Use specific release tag (e.g. v1.9.0) instead of latest matching
  -h, --help       Show help

This script will download the appropriate 'kanata_macos_cmd_allowed_*' asset for your
architecture (arm64 or x86_64), verify checksum if available in the release body, and
install to $INSTALL_PATH (backing up previous binary if present). Use --dry-run to
only download and verify without moving the binary into place.
EOF
}

ARCH=$(uname -m)
case "$ARCH" in
  arm64) ASSET_NAME="kanata_macos_cmd_allowed_arm64" ;;
  x86_64|i386) ASSET_NAME="kanata_macos_cmd_allowed_x86_64" ;;
  *) echo "Unsupported arch: $ARCH" >&2; exit 1 ;;
esac

FORCE_NO_PROMPT=no
DRY_RUN=no
SPEC_TAG=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes) FORCE_NO_PROMPT=yes; shift ;;
    --dry-run) DRY_RUN=yes; shift ;;
    --tag) SPEC_TAG="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

mkdir -p "$TMPDIR"
trap 'rm -rf "$TMPDIR"' EXIT

echo "Detected arch: $ARCH -> looking for asset: $ASSET_NAME"

# Fetch releases list
RELS_JSON=$(curl -sSf "$API")

# Helper: prefer jq if available for robust parsing
if command -v jq >/dev/null 2>&1; then
  if [[ -n "$SPEC_TAG" ]]; then
    RELEASE=$(echo "$RELS_JSON" | jq -r --arg tag "$SPEC_TAG" '.[] | select(.tag_name==$tag) | @json' | head -n1 || true)
  else
    RELEASE=$(echo "$RELS_JSON" | jq -r --arg asset "$ASSET_NAME" '.[] | select(any(.assets[]?; .name == $asset)) | @json' | head -n1 || true)
  fi
  if [[ -z "$RELEASE" || "$RELEASE" == "null" ]]; then
    echo "No release found containing asset $ASSET_NAME" >&2
    exit 1
  fi
  DOWNLOAD_URL=$(echo "$RELEASE" | jq -r --arg asset "$ASSET_NAME" '.assets[] | select(.name==$asset) | .browser_download_url')
  RELEASE_BODY=$(echo "$RELEASE" | jq -r '.body')
  RELEASE_TAG=$(echo "$RELEASE" | jq -r '.tag_name')
else
  # Fallback brittle parsing without jq
  if [[ -n "$SPEC_TAG" ]]; then
    RELEASE_JSON=$(curl -sSf "$API/releases/tags/$SPEC_TAG")
  else
    # find first release block containing the asset name
    DOWNLOAD_URL=$(echo "$RELS_JSON" | grep -A40 "\"name\": \"$ASSET_NAME\"" -m1 | grep 'browser_download_url' | sed -E 's/.*"(https:[^"]+)".*/\1/')
    # to get release body / tag, find surrounding release by searching for earlier tag_name
    RELEASE_TAG=$(echo "$RELS_JSON" | grep -B40 "\"name\": \"$ASSET_NAME\"" -m1 | grep 'tag_name' | head -n1 | sed -E 's/.*"([^"]+)".*/\1/')
    RELEASE_JSON=""
    RELEASE_BODY=""
  fi
  # If SPEC_TAG used, derive DOWNLOAD_URL and RELEASE_BODY
  if [[ -n "$SPEC_TAG" ]]; then
    DOWNLOAD_URL=$(echo "$RELEASE_JSON" | grep 'browser_download_url' -m1 | sed -E 's/.*"(https:[^"]+)".*/\1/') || true
    RELEASE_BODY=$(echo "$RELEASE_JSON" | sed -n '1,200p') || true
  fi
fi

if [[ -z "$DOWNLOAD_URL" || "$DOWNLOAD_URL" == "null" ]]; then
  echo "Failed to find download URL for $ASSET_NAME in releases." >&2
  exit 1
fi

echo "Found release: ${RELEASE_TAG:-<unknown>}"
echo "Download URL: $DOWNLOAD_URL"

OUT="$TMPDIR/$ASSET_NAME"

echo "Downloading..."
curl -L --fail -o "$OUT" "$DOWNLOAD_URL"
chmod +x "$OUT"

# Try to extract checksum from release body (SHA256) if we have it
EXPECTED_SUM=""
if [[ -n "$RELEASE_BODY" ]]; then
  # Look for a 64-hex checksum on same or nearby lines mentioning asset name
  EXPECTED_SUM=$(printf "%s" "$RELEASE_BODY" | grep -Eo "[a-f0-9]{64}  ?$ASSET_NAME" | awk '{print $1}' | head -n1 || true)
  if [[ -z "$EXPECTED_SUM" ]]; then
    # maybe formatted as: <sha>  kanata_macos_cmd_allowed_arm64
    EXPECTED_SUM=$(printf "%s" "$RELEASE_BODY" | grep -Eo "[a-f0-9]{64}" | head -n1 || true)
  fi
fi

if [[ -n "$EXPECTED_SUM" ]]; then
  echo "Found expected SHA256 in release notes: $EXPECTED_SUM"
  CALC_SUM=$(shasum -a 256 "$OUT" | awk '{print $1}')
  if [[ "$CALC_SUM" != "$EXPECTED_SUM" ]]; then
    echo "Checksum mismatch: calculated $CALC_SUM != expected $EXPECTED_SUM" >&2
    exit 1
  fi
  echo "Checksum OK"
else
  echo "No checksum found in release notes. You may want to verify manually." >&2
fi

# ensure we have a calculated checksum for reporting
if [[ -z "${CALC_SUM:-}" && -f "$OUT" ]]; then
  CALC_SUM=$(shasum -a 256 "$OUT" | awk '{print $1}') || true
fi

if [[ "$DRY_RUN" == "yes" ]]; then
  echo "Dry-run: downloaded $ASSET_NAME to $OUT"
  if [[ -n "${CALC_SUM:-}" ]]; then
    echo "Checksum: $CALC_SUM${EXPECTED_SUM:+ (expected: $EXPECTED_SUM)}"
  fi
  echo "Not installing due to --dry-run."
  exit 0
fi

if [[ "$FORCE_NO_PROMPT" != "yes" ]]; then
  echo "Ready to install $ASSET_NAME to $INSTALL_PATH (will backup existing binary as ${INSTALL_PATH}.bak). Continue? [y/N]"
  read -r yn
  if [[ "$yn" != "y" && "$yn" != "Y" ]]; then
    echo "Aborted."
    exit 0
  fi
fi

# Backup existing
if [[ -x "$INSTALL_PATH" ]]; then
  echo "Backing up existing $INSTALL_PATH to ${INSTALL_PATH}.bak"
  sudo mv -f "$INSTALL_PATH" "${INSTALL_PATH}.bak"
fi

sudo mv "$OUT" "$INSTALL_PATH"
sudo chown root:wheel "$INSTALL_PATH"
sudo chmod 755 "$INSTALL_PATH"

echo "Installed $INSTALL_PATH"
echo "Installed binary version:"
"$INSTALL_PATH" --version || true

echo "Done. Remember to restart Kanata/daemon if required."
