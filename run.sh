#!/usr/bin/env bash
# run.sh — Start the FiveM server on Linux / macOS
# Usage: ./run.sh [path-to-server-binary]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Configuration ─────────────────────────────────────────────────────────────
# Path to the FiveM server binary (FXServer).
# Default: look for it next to this script, then fall back to $PATH.
FXSERVER="${FXSERVER:-}"

if [[ -z "$FXSERVER" ]]; then
    if [[ -x "$SCRIPT_DIR/FXServer" ]]; then
        FXSERVER="$SCRIPT_DIR/FXServer"
    elif command -v FXServer &>/dev/null; then
        FXSERVER="FXServer"
    else
        echo "ERROR: FXServer binary not found."
        echo "  1. Download the server from https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/"
        echo "  2. Extract it into this directory, OR"
        echo "  3. Set the FXSERVER environment variable to its path."
        exit 1
    fi
fi

# ── Launch ─────────────────────────────────────────────────────────────────────
echo "Starting FiveM server..."
exec "$FXSERVER" +exec "$SCRIPT_DIR/server.cfg" "$@"
