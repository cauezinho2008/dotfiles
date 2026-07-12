#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

for file in \
    plasmashellrc \
    plasmarc \
    plasma-org.kde.plasma.desktop-appletsrc
do
    [[ -f "$REPO_DIR/.config/$file" ]] &&
        cp -f "$REPO_DIR/.config/$file" "$HOME/.config/"
done

#kquitapp6 plasmashell 2>/dev/null \
#|| kquitapp5 plasmashell 2>/dev/null \
#|| true

#kstart6 plasmashell >/dev/null 2>&1 \
#|| kstart5 plasmashell >/dev/null 2>&1 \
#|| plasmashell >/dev/null 2>&1 &
