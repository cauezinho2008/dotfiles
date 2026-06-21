#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

FILES=(
    powerdevilrc
    powermanagementprofilesrc
)

for file in "${FILES[@]}"; do
    [[ -f "$REPO_DIR/.config/$file" ]] &&
        cp -a "$REPO_DIR/.config/$file" "$HOME/.config/"
done

qdbus org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement reparseConfiguration 2>/dev/null || true
