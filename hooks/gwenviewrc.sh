#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

[[ -f "$REPO_DIR/.config/gwenviewrc" ]] &&
    sed "s|\$HOME|$HOME|g" "$REPO_DIR/.config/gwenviewrc" > "$HOME/.config/gwenviewrc"

pkill gwenview 2>/dev/null || true