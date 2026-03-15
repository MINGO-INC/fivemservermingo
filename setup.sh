#!/usr/bin/env bash
# setup.sh — Steps 2 and 3: Download FXServer and cfx-server-data (Linux / macOS)
# Run this once from the repo root before starting the server with run.sh.
#
# Requirements:
#   • curl (pre-installed on most Linux distros and macOS)
#   • wget or curl for downloading archives
#   • tar  (for extracting the FXServer archive)
#   • git  (for cloning cfx-server-data)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Validate OS ───────────────────────────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
    Linux|Darwin) ;;
    *)
        echo "ERROR: Unsupported OS: $OS"
        echo "Please perform setup manually by following the instructions in README.md."
        exit 1
        ;;
esac

# ── Step 2: Download FiveM server binary ──────────────────────────────────────

echo
echo "=== Step 2: Downloading FiveM server binary ==="
echo

if [[ -x "$SCRIPT_DIR/FXServer" ]]; then
    echo "FXServer binary already present -- skipping download."
else
    VERSIONS_URL="https://changelogs-live.fivem.net/api/changelog/versions/linux/server"
    ARTIFACT_BASE="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master"
    ARCHIVE_NAME="server.tar.xz"

    if ! command -v python3 &>/dev/null; then
        echo "ERROR: python3 is required to parse the version API response but was not found."
        echo "Install python3 or download FXServer manually from:"
        echo "  $ARTIFACT_BASE"
        exit 1
    fi

    echo "Fetching latest FXServer version..."
    VERSIONS_JSON="$(curl -fsSL "$VERSIONS_URL")"
    LATEST_VERSION="$(printf '%s' "$VERSIONS_JSON" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d['latest'])" 2>/dev/null || true)"

    if [[ -z "$LATEST_VERSION" ]]; then
        echo "ERROR: Could not fetch the latest FXServer version number."
        echo "The FiveM changelog API may be unreachable, or the response format has changed."
        echo "Please download FXServer manually from:"
        echo "  $ARTIFACT_BASE"
        exit 1
    fi

    ARCHIVE_URL="${ARTIFACT_BASE}/${LATEST_VERSION}/${ARCHIVE_NAME}"
    echo "Latest version: $LATEST_VERSION"
    echo "Downloading: $ARCHIVE_URL"
    echo

    curl -fL --progress-bar -o "$SCRIPT_DIR/fx.tar.xz" "$ARCHIVE_URL"

    if [[ ! -f "$SCRIPT_DIR/fx.tar.xz" ]]; then
        echo "ERROR: Download failed."
        echo "Please download FXServer manually from:"
        echo "  $ARTIFACT_BASE"
        exit 1
    fi

    echo "Extracting archive..."
    tar -xf "$SCRIPT_DIR/fx.tar.xz" -C "$SCRIPT_DIR"
    rm -f "$SCRIPT_DIR/fx.tar.xz"

    # Make the binary executable (should already be, but be explicit)
    if [[ ! -x "$SCRIPT_DIR/FXServer" ]]; then
        # FXServer may be inside a sub-directory after extraction; search for it
        FXPATH="$(find "$SCRIPT_DIR" -maxdepth 2 -name 'FXServer' -type f | head -n 1)"
        if [[ -n "$FXPATH" && "$FXPATH" != "$SCRIPT_DIR/FXServer" ]]; then
            mv "$FXPATH" "$SCRIPT_DIR/FXServer"
        fi
        chmod +x "$SCRIPT_DIR/FXServer" 2>/dev/null || true
    fi

    if [[ ! -f "$SCRIPT_DIR/FXServer" ]]; then
        echo "ERROR: FXServer binary not found after extraction."
        echo "The archive layout may have changed."
        echo "Please download and extract FXServer manually from:"
        echo "  $ARTIFACT_BASE"
        exit 1
    fi

    echo "FXServer downloaded and extracted successfully."
fi

# ── Step 3: Clone and merge cfx-server-data ───────────────────────────────────

echo
echo "=== Step 3: Downloading default server data (cfx-server-data) ==="
echo

if [[ ! -d "$SCRIPT_DIR/cfx-server-data" ]]; then
    echo "Cloning cfx-server-data..."
    git clone https://github.com/citizenfx/cfx-server-data.git "$SCRIPT_DIR/cfx-server-data"
else
    echo "cfx-server-data already present -- skipping clone."
fi

echo
echo "Merging resources into resources/ ..."
echo "(Only new files are copied -- existing files are not overwritten.)"
echo

# cp -rn copies recursively without overwriting existing files.
if ! cp -rn "$SCRIPT_DIR/cfx-server-data/resources/." "$SCRIPT_DIR/resources/"; then
    echo "ERROR: Failed to merge cfx-server-data resources into resources/."
    echo "Check that you have write permission to the resources/ directory."
    exit 1
fi

echo
echo "============================================================"
echo " Setup complete!"
echo "============================================================"
echo
echo " Next steps:"
echo "   1. Open server.cfg and uncomment + set sv_licenseKey"
echo "      (get a free key at https://keymaster.fivem.net)"
echo "   2. Run ./run.sh to start the server"
echo
