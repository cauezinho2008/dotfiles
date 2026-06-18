#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/cauezinho2008/dotfiles.git"
TEMP_DIR="$(mktemp -d /tmp/caue-dotfiles-XXXXXX)"

cleanup() {
    rm -rf "$TEMP_DIR"
}

trap cleanup EXIT

echo "Downloading dotfiles..."
git clone --depth=1 "$REPO_URL" "$TEMP_DIR" >/dev/null 2>&1

cd "$TEMP_DIR"

exec bash "$TEMP_DIR/main.sh"
