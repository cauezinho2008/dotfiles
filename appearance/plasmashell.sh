#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

for file in plasmashellrc plasmarc; do
    [[ -f "$REPO_DIR/.config/$file" ]] &&
        cp -f "$REPO_DIR/.config/$file" "$HOME/.config/"
done

APPLETS="$REPO_DIR/.config/plasma-org.kde.plasma.desktop-appletsrc"
if [[ -f "$APPLETS" ]]; then
    sed "s|\$HOME|$HOME|g" "$APPLETS" > "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
fi

