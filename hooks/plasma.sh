#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

FILES=(
    kdeglobals
    plasmarc
    plasmashellrc
    plasma-org.kde.plasma.desktop-appletsrc
    kwinrc
    kwinrulesrc
    ksmserverrc
    kactivitymanagerdrc
    baloofilerc
    kdedefaults
)

for file in "${FILES[@]}"; do
    [[ -f "$REPO_DIR/.config/$file" ]] &&
        cp -a "$REPO_DIR/.config/$file" "$HOME/.config/"
done

# optional defaults
[[ -d "$REPO_DIR/.config/kdedefaults" ]] &&
    cp -a "$REPO_DIR/.config/kdedefaults" "$HOME/.config/"

# reload
qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.reloadConfig 2>/dev/null || true

kquitapp6 plasmashell 2>/dev/null || true
kstart6 plasmashell >/dev/null 2>&1 &
