#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

[[ -f "$REPO_DIR/.config/dolphinrc" ]] &&
    cp -a "$REPO_DIR/.config/dolphinrc" "$HOME/.config/"

[[ -d "$REPO_DIR/.local/share/dolphin" ]] &&
    cp -a "$REPO_DIR/.local/share/dolphin" "$HOME/.local/share/"

# restart dolphin if open
pkill dolphin 2>/dev/null || true
