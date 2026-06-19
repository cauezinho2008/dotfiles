#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/cauezinho2008/dotfiles.git"

# remove all previous unfinished sessions
find /tmp -maxdepth 1 -type d -name "caue-dotfiles-*" -exec rm -rf {} + 2>/dev/null || true

TEMP_DIR="$(mktemp -d /tmp/caue-dotfiles-XXXXXX)"

cleanup() {
    rm -rf "$TEMP_DIR"
}

trap cleanup EXIT INT TERM

echo "Downloading dotfiles..."
git clone --depth=1 "$REPO_URL" "$TEMP_DIR" >/dev/null 2>&1

cd "$TEMP_DIR"

bash "$TEMP_DIR/main.sh"
