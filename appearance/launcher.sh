#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

cp -f \
"$REPO_DIR/.config/plasma-org.kde.plasma.desktop-appletsrc" \
"$HOME/.config/"

kquitapp6 plasmashell 2>/dev/null \
|| kquitapp5 plasmashell 2>/dev/null \
|| true

kstart6 plasmashell >/dev/null 2>&1 \
|| kstart5 plasmashell >/dev/null 2>&1 \
|| plasmashell >/dev/null 2>&1 &
