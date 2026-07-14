#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

for file in plasmashellrc plasmarc; do
    if [[ -f "$REPO_DIR/.config/$file" ]]; then
        sed "s|\$HOME|$HOME|g" "$REPO_DIR/.config/$file" > "$HOME/.config/$file"
    fi
done

APPLETS="$REPO_DIR/.config/plasma-org.kde.plasma.desktop-appletsrc"
if [[ -f "$APPLETS" ]]; then
    sed "s|\$HOME|$HOME|g" "$APPLETS" > "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
fi

