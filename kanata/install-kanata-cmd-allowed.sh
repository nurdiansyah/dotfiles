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
Usage: $0 [--yes] [--dry-run] [--force] [--tag <tag>] [--asset <asset_name>] [--fallback-latest]

Options:
  --yes            Non-interactive, install without prompt
  --dry-run        Download + verify but do NOT install the binary
  --force          Force re-download even if cached asset exists
  --tag <tag>      Use specific release tag (e.g. v1.9.0) instead of latest matching
  --asset <name>   Override the asset name to download (useful if package name changed)
  --fallback-latest  If specified, allow falling back to the latest release that contains the desired asset when the given tag does not contain it
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
FORCE_DOWNLOAD=no
SPEC_TAG=""
ASSET_OVERRIDE=""
ALLOW_FALLBACK=no
while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes) FORCE_NO_PROMPT=yes; shift ;;
    --dry-run) DRY_RUN=yes; shift ;;
    --force) FORCE_DOWNLOAD=yes; shift ;;
    --tag) SPEC_TAG="$2"; shift 2 ;;
    --asset) ASSET_OVERRIDE="$2"; shift 2 ;;
    --fallback-latest) ALLOW_FALLBACK=yes; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

# If user supplied an explicit asset override, use it
if [[ -n "$ASSET_OVERRIDE" ]]; then
  ASSET_NAME="$ASSET_OVERRIDE"
fi

mkdir -p "$TMPDIR"
trap 'rm -rf "$TMPDIR"' EXIT

echo "Detected arch: $ARCH -> looking for asset: $ASSET_NAME"

# Fetch releases list
RELS_JSON=$(curl -sSf "$API")

# Helper: prefer jq if available for robust parsing
if command -v jq >/dev/null 2>&1; then
  if [[ -n "$SPEC_TAG" ]]; then
    # Try the provided tag, then try with a leading 'v' (accept both '1.2.3' and 'v1.2.3')
    RELEASE=""
    for t in "$SPEC_TAG" "v$SPEC_TAG"; do
      RELEASE=$(echo "$RELS_JSON" | jq -r --arg tag "$t" '.[] | select(.tag_name==$tag) | @json' | head -n1 || true)
      if [[ -n "$RELEASE" && "$RELEASE" != "null" ]]; then
        SPEC_TAG="$t"
        break
      fi
    done
  else
    RELEASE=$(echo "$RELS_JSON" | jq -r --arg asset "$ASSET_NAME" '.[] | select(any(.assets[]?; .name == $asset)) | @json' | head -n1 || true)
  fi
  if [[ -z "$RELEASE" || "$RELEASE" == "null" ]]; then
    echo "No release found${SPEC_TAG:+ for tag $SPEC_TAG} containing asset $ASSET_NAME" >&2
    exit 1
  fi
  DOWNLOAD_URL=$(echo "$RELEASE" | jq -r --arg asset "$ASSET_NAME" '.assets[] | select(.name==$asset) | .browser_download_url')
  RELEASE_BODY=$(echo "$RELEASE" | jq -r '.body')
  RELEASE_TAG=$(echo "$RELEASE" | jq -r '.tag_name')
else
  # Fallback brittle parsing without jq
  if [[ -n "$SPEC_TAG" ]]; then
    # Try the requested tag first, then try with a leading 'v' if that fails
    RELEASE_JSON=""
    for t in "$SPEC_TAG" "v$SPEC_TAG"; do
      tmp=$(curl -sSf "$API/releases/tags/$t" 2>/dev/null) || tmp=""
      if [[ -n "$tmp" ]]; then
        RELEASE_JSON="$tmp"
        SPEC_TAG="$t"
        break
      fi
    done
  else
    # find first release block containing the asset name
    DOWNLOAD_URL=$(echo "$RELS_JSON" | grep -A40 "\"name\": \"$ASSET_NAME\"" -m1 | grep 'browser_download_url' | sed -E 's/.*"(https:[^"]+)".*/\1/')
    # to get release body / tag, find surrounding release by searching for earlier tag_name
    RELEASE_TAG=$(echo "$RELS_JSON" | grep -B40 "\"name\": \"$ASSET_NAME\"" -m1 | grep 'tag_name' | head -n1 | sed -E 's/.*"([^\"]+)".*/\1/')
    RELEASE_JSON=""
    RELEASE_BODY=""
  fi
  # If SPEC_TAG used, derive DOWNLOAD_URL and RELEASE_BODY
  if [[ -n "$SPEC_TAG" && -n "$RELEASE_JSON" ]]; then
    DOWNLOAD_URL=$(echo "$RELEASE_JSON" | grep 'browser_download_url' -m1 | sed -E 's/.*"(https:[^"]+)".*/\1/') || true
    RELEASE_BODY=$(echo "$RELEASE_JSON" | sed -n '1,200p') || true
    RELEASE_TAG=$(echo "$RELEASE_JSON" | grep -m1 '"tag_name"' | sed -E 's/.*"([^\"]+)".*/\1/') || true
  fi
  if [[ -n "$SPEC_TAG" && -z "$RELEASE_JSON" ]]; then
    echo "No release found for tag(s): $SPEC_TAG and v$SPEC_TAG" >&2
    exit 1
  fi
fi

if [[ -z "$DOWNLOAD_URL" || "$DOWNLOAD_URL" == "null" ]]; then
  if [[ -n "$SPEC_TAG" ]]; then
    echo "Release $SPEC_TAG found but it does not contain asset $ASSET_NAME." >&2

    # List available assets in the specified tag to help the user diagnose changed package names
    echo "Available assets in release $SPEC_TAG:" >&2
    if command -v jq >/dev/null 2>&1; then
      echo "$RELEASE" | jq -r '.assets[]?.name' | sed 's/^/  - /' >&2
    else
      # best-effort parsing without jq
      if [[ -n "$RELEASE_JSON" ]]; then
        echo "$RELEASE_JSON" | grep '"name":' | sed -E 's/.*"([^"]+)".*/  - \1/' >&2
      else
        # fallback to direct API call for the tag
        TAG_JSON=$(curl -sSf "$API/releases/tags/$SPEC_TAG" 2>/dev/null || true)
        if [[ -n "$TAG_JSON" ]]; then
          echo "$TAG_JSON" | grep '"name":' | sed -E 's/.*"([^"]+)".*/  - \1/' >&2
        fi
      fi
    fi

    # Attempt to detect macOS packaged archive for this arch (e.g., kanata-macos-binaries-arm64-<tag>.zip)
    if command -v jq >/dev/null 2>&1; then
      ALT_ARCHIVE_URL=$(echo "$RELEASE" | jq -r --arg arch "$ARCH" '.assets[] | select(.name | test("macos.*" + (if $arch=="arm64" then "arm64" else "(x64|x86)" end); "i")) | .browser_download_url' | head -n1 || true)
      ALT_ARCHIVE_NAME=$(echo "$RELEASE" | jq -r --arg arch "$ARCH" '.assets[] | select(.name | test("macos.*" + (if $arch=="arm64" then "arm64" else "(x64|x86)" end); "i")) | .name' | head -n1 || true)
    else
      ALT_ARCHIVE_URL=$(echo "$RELEASE_JSON" | grep -i 'macos' -m1 | grep -o 'https:[^" ]*' || true)
      ALT_ARCHIVE_NAME=$(echo "$RELEASE_JSON" | grep -i 'macos' -m1 | sed -E 's/.*"([^"]+)".*/\1/' || true)
    fi

    if [[ -n "$ALT_ARCHIVE_URL" ]]; then
      echo "Detected packaged macOS asset for this release: ${ALT_ARCHIVE_NAME:-<download>}" >&2
      echo "Will attempt to extract the kanata binary from the archive for arch $ARCH." >&2
      DOWNLOAD_URL="$ALT_ARCHIVE_URL"
      ARCHIVE_ASSET=yes
      ARCHIVE_ASSET_NAME="$ALT_ARCHIVE_NAME"      # Try to get asset digest from release metadata (jq preferred) so we can verify the downloaded archive
      if command -v jq >/dev/null 2>&1; then
        ARCHIVE_DIGEST=$(echo "$RELEASE" | jq -r --arg n "$ARCHIVE_ASSET_NAME" '.assets[] | select(.name==$n) | .digest' || true)
        ARCHIVE_DIGEST=${ARCHIVE_DIGEST#sha256:}
      fi    elif [[ "$ALLOW_FALLBACK" == "yes" ]]; then
      echo "Falling back to the latest release that contains $ASSET_NAME..."
      SPEC_TAG=""
      # Find latest release that contains the asset
      if command -v jq >/dev/null 2>&1; then
        RELEASE=$(echo "$RELS_JSON" | jq -r --arg asset "$ASSET_NAME" '.[] | select(any(.assets[]?; .name == $asset)) | @json' | head -n1 || true)
        if [[ -n "$RELEASE" && "$RELEASE" != "null" ]]; then
          DOWNLOAD_URL=$(echo "$RELEASE" | jq -r --arg asset "$ASSET_NAME" '.assets[] | select(.name==$asset) | .browser_download_url')
          RELEASE_BODY=$(echo "$RELEASE" | jq -r '.body')
          RELEASE_TAG=$(echo "$RELEASE" | jq -r '.tag_name')
        fi
      else
        DOWNLOAD_URL=$(echo "$RELS_JSON" | grep -A40 "\"name\": \"$ASSET_NAME\"" -m1 | grep 'browser_download_url' | sed -E 's/.*"(https:[^"]+)".*/\1/') || true
        RELEASE_TAG=$(echo "$RELS_JSON" | grep -B40 "\"name\": \"$ASSET_NAME\"" -m1 | grep 'tag_name' | head -n1 | sed -E 's/.*"([^\"]+)".*/\1/') || true
      fi
      if [[ -z "$DOWNLOAD_URL" || "$DOWNLOAD_URL" == "null" ]]; then
        echo "Could not find any release containing $ASSET_NAME" >&2
        exit 1
      fi
    else
      echo "Use --fallback-latest to allow falling back to the latest release containing $ASSET_NAME, or re-run with --asset <asset_name> if the package name changed." >&2
      exit 1
    fi
  else
    echo "Failed to find download URL for $ASSET_NAME in releases." >&2
    exit 1
  fi
fi

echo "Found release: ${RELEASE_TAG:-<unknown>}"
echo "Download URL: $DOWNLOAD_URL"

# Cache directory to avoid re-downloading same asset repeatedly
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/kanata"
mkdir -p "$CACHE_DIR"
CACHE_FILE="$CACHE_DIR/${ASSET_NAME}-${RELEASE_TAG:-latest}"

# Try to obtain asset size (jq preferred)
ASSET_SIZE=""
if command -v jq >/dev/null 2>&1; then
  ASSET_SIZE=$(echo "$RELEASE" | jq -r --arg asset "$ASSET_NAME" '.assets[] | select(.name==$asset) | .size // empty') || true
fi

# default to avoid unbound variable under 'set -u'
EXPECTED_SUM=""

# Prefer any existing cached asset (from any release) unless user requested a specific tag or --force
USED_CACHED_ANY=no
if [[ -z "$SPEC_TAG" && "$FORCE_DOWNLOAD" != "yes" ]]; then
  CACHED_ANY=$(ls -t "$CACHE_DIR/${ASSET_NAME}-"* 2>/dev/null | head -n1 || true)
  if [[ -n "$CACHED_ANY" && -f "$CACHED_ANY" ]]; then
    echo "Found existing cached asset (any release): $CACHED_ANY"
    echo "Using cached asset instead of downloading latest release (use --force to re-download or --tag to pick a specific release)."
    OUT="$CACHED_ANY"
    SKIP_DOWNLOAD=yes
    USED_CACHED_ANY=yes
  fi
fi

SKIP_DOWNLOAD=${SKIP_DOWNLOAD:-no}
# If cached file exists and user did not ask to force download, try to verify
if [[ "$SKIP_DOWNLOAD" != "yes" && -f "$CACHE_FILE" && "$FORCE_DOWNLOAD" != "yes" ]]; then
  echo "Found cached asset: $CACHE_FILE"
  if [[ -n "$EXPECTED_SUM" ]]; then
    echo "Verifying cached asset checksum..."
    CALC_SUM=$(shasum -a 256 "$CACHE_FILE" | awk '{print $1}') || CALC_SUM=""
    if [[ -n "$CALC_SUM" && "$CALC_SUM" == "$EXPECTED_SUM" ]]; then
      echo "Using cached asset (checksum matches)."
      OUT="$CACHE_FILE"
      SKIP_DOWNLOAD=yes
    else
      echo "Cached checksum mismatch; will re-download." >&2
    fi
  elif [[ -n "$ASSET_SIZE" ]]; then
    CACHE_SIZE=$(stat -f%z "$CACHE_FILE" 2>/dev/null || stat -c%s "$CACHE_FILE" 2>/dev/null || echo 0)
    if [[ "$CACHE_SIZE" -eq "$ASSET_SIZE" ]]; then
      echo "Using cached asset (size $CACHE_SIZE matches expected $ASSET_SIZE)."
      OUT="$CACHE_FILE"
      SKIP_DOWNLOAD=yes
    else
      echo "Cached file size mismatch; will re-download." >&2
    fi
  else
    # No reliable metadata available; assume cache is valid to avoid re-downloading
    echo "No checksum/size available for verification; using cached asset by default."
    OUT="$CACHE_FILE"
    SKIP_DOWNLOAD=yes
  fi
fi

if [[ "$SKIP_DOWNLOAD" == "no" ]]; then
  OUT_TMP="$TMPDIR/$ASSET_NAME"
  echo "Downloading..."
  curl -L --fail -o "$OUT_TMP" "$DOWNLOAD_URL"
  chmod +x "$OUT_TMP"

  # If this was an archive (zip) containing the macOS binaries, try to extract the appropriate binary
  if [[ "${ARCHIVE_ASSET:-no}" == "yes" ]]; then
    echo "Detected downloaded archive; inspecting contents to extract kanata binary..."
    # List zip contents and prefer filenames in this order: 'cmd_allowed' -> 'kanata_macos_cmd_allowed' -> 'kanata_macos' -> 'kanata'
    LISTING=$(unzip -l "$OUT_TMP" 2>/dev/null || true)
    FILES=$(printf "%s" "$LISTING" | awk '{print $4}')

    # preferred order
    CAND=$(printf "%s\n" "$FILES" | grep -i 'cmd_allowed' | head -n1 || true)
    if [[ -z "$CAND" ]]; then
      CAND=$(printf "%s\n" "$FILES" | grep -i 'kanata_macos_cmd_allowed' | head -n1 || true)
    fi
    if [[ -z "$CAND" ]]; then
      CAND=$(printf "%s\n" "$FILES" | grep -i 'kanata_macos' | head -n1 || true)
    fi
    if [[ -z "$CAND" ]]; then
      CAND=$(printf "%s\n" "$FILES" | grep -E '/kanata$|^kanata$' -i | head -n1 || true)
    fi

    if [[ -z "$CAND" ]]; then
      echo "Could not find a kanata binary inside the archive $ARCHIVE_ASSET_NAME" >&2
      echo "Available files:" >&2
      printf "%s" "$FILES" | sed 's/^/  - /' >&2
      exit 1
    fi
    echo "Extracting $CAND from archive..."
    unzip -p "$OUT_TMP" "$CAND" > "$TMPDIR/kanata_extracted" || {
      echo "Failed to extract $CAND from archive" >&2; exit 1
    }
    chmod +x "$TMPDIR/kanata_extracted"
    mv -f "$TMPDIR/kanata_extracted" "$CACHE_FILE-extracted"
    chmod +x "$CACHE_FILE-extracted"
    OUT="$CACHE_FILE-extracted"
  else
    # Move into cache for future runs
    mv -f "$OUT_TMP" "$CACHE_FILE"
    chmod +x "$CACHE_FILE"
    OUT="$CACHE_FILE"
  fi
fi

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
    # If we extracted from an archive, try to consult a sha256sums asset for a match (inner file or archive)
    if [[ "${ARCHIVE_ASSET:-no}" == "yes" ]]; then
      echo "Checksum mismatch for extracted binary; attempting to consult release sha256sums..." >&2
      SHA256S_URL=""
      if command -v jq >/dev/null 2>&1; then
        SHA256S_URL=$(echo "$RELEASE" | jq -r '.assets[] | select(.name=="sha256sums") | .browser_download_url' || true)
      else
        SHA256S_URL=$(echo "$RELEASE_JSON" | grep -i '"name": "sha256sums"' -B2 | grep -o 'https:[^" ]*' || true)
      fi
      if [[ -n "$SHA256S_URL" ]]; then
        curl -sSf "$SHA256S_URL" -o "$TMPDIR/sha256sums" || true
        # Try to match the extracted filename first
        EXPECTED_FROM_SUMS=$(grep -E "[a-f0-9]{64}[[:space:]]+$CAND" "$TMPDIR/sha256sums" | awk '{print $1}' | head -n1 || true)
        if [[ -n "$EXPECTED_FROM_SUMS" ]]; then
          if [[ "$CALC_SUM" == "$EXPECTED_FROM_SUMS" ]]; then
            echo "Checksum OK (matched sha256sums entry for $CAND)"
          else
            # Maybe the sha lists the zip; compare zip checksum
            ZIP_SUM=$(shasum -a 256 "$OUT_TMP" | awk '{print $1}') || ZIP_SUM=""
            EXPECTED_ZIP=$(grep -E "[a-f0-9]{64}[[:space:]]+${ARCHIVE_ASSET_NAME}" "$TMPDIR/sha256sums" | awk '{print $1}' | head -n1 || true)
            if [[ -n "$EXPECTED_ZIP" && "$ZIP_SUM" == "$EXPECTED_ZIP" ]]; then
              echo "Archive checksum matches sha256sums (using binary extracted from verified archive)."
            else
              echo "Checksum mismatch: calculated $CALC_SUM != expected $EXPECTED_FROM_SUMS" >&2
              exit 1
            fi
          fi
        else
          # No match for inner file in sums; try archive name
          ZIP_SUM=$(shasum -a 256 "$OUT_TMP" | awk '{print $1}') || ZIP_SUM=""
          EXPECTED_ZIP=$(grep -E "[a-f0-9]{64}  ?${ARCHIVE_ASSET_NAME}" "$TMPDIR/sha256sums" | awk '{print $1}' | head -n1 || true)
          if [[ -n "$EXPECTED_ZIP" && "$ZIP_SUM" == "$EXPECTED_ZIP" ]]; then
            echo "Archive checksum matches sha256sums (using binary extracted from verified archive)."
          elif [[ -n "${ARCHIVE_DIGEST:-}" && "$ZIP_SUM" == "${ARCHIVE_DIGEST}" ]]; then
            echo "Archive checksum matches release metadata digest (using binary extracted from verified archive)."
          else
            echo "Checksum mismatch and no matching sha256sums entry found." >&2
            exit 1
          fi
        fi
      else
        # No sha256sums asset available; fallback to previous behavior
        if [[ "$USED_CACHED_ANY" == "yes" ]]; then
          echo "Warning: cached asset checksum ($CALC_SUM) does not match expected ($EXPECTED_SUM), but using cached file per preference." >&2
        else
          echo "Checksum mismatch: calculated $CALC_SUM != expected $EXPECTED_SUM" >&2
          exit 1
        fi
      fi
    else
      if [[ "$USED_CACHED_ANY" == "yes" ]]; then
        echo "Warning: cached asset checksum ($CALC_SUM) does not match expected ($EXPECTED_SUM), but using cached file per preference." >&2
      else
        echo "Checksum mismatch: calculated $CALC_SUM != expected $EXPECTED_SUM" >&2
        exit 1
      fi
    fi
  else
    echo "Checksum OK"
    fi
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
