#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

[[ -f "$REPO_DIR/.config/kwriterc" ]] &&
    sed "s|\$HOME|$HOME|g" "$REPO_DIR/.config/kwriterc" > "$HOME/.config/kwriterc"

pkill kwrite 2>/dev/null || true