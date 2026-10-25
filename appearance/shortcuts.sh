#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$HOME/.config"

# Copy the full kglobalshortcutsrc from repo (contains all shortcuts including kitty Meta+T)
cp -f "$REPO_DIR/.config/kglobalshortcutsrc" "$HOME/.config/"

# Explicitly unassign Meta+T from Plasma tiling (Edit Tiles in kwin group)
# This ensures it's disabled even if the repo file somehow gets out of sync
kwriteconfig6 --file "$HOME/.config/kglobalshortcutsrc" --group kwin --key "Edit Tiles" "none,none,Toggle Tiles Editor"

# Reload shortcuts daemon to apply changes
kquitapp6 kglobalacceld 2>/dev/null || true
sleep 1
kglobalacceld 2>/dev/null || true

# Verify the changes took effect
if grep -q "Edit Tiles=none,none" "$HOME/.config/kglobalshortcutsrc"; then
    echo "Shortcuts applied: Meta+T unassigned from tiling, kitty shortcut active"
else
    echo "Warning: Edit Tiles may not have been updated correctly"
fi
