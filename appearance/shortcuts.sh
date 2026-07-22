#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$HOME/.config"

cp -f "$REPO_DIR/.config/kglobalshortcutsrc" \
      "$HOME/.config/"

# Unassign Meta+T from Plasma tiling to avoid conflict with kitty
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Edit Tiles" "none,none,Toggle Tiles Editor"

