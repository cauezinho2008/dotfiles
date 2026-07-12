#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$REPO_DIR/wallpapers"
DST_DIR="$HOME/Pictures/Wallpapers"

mkdir -p "$DST_DIR"

wallpaper="$(find "$SRC_DIR" -maxdepth 1 -type f | head -n1)"
[[ -z "$wallpaper" ]] && exit 0

cp -f "$wallpaper" "$DST_DIR/"

WALL="$DST_DIR/$(basename "$wallpaper")"

echo "Applying wallpaper..."

# Desktop
plasma-apply-wallpaperimage "$WALL" >/dev/null 2>&1 || true

# Lock screen
kwriteconfig6 \
    --file kscreenlockerrc \
    --group Greeter \
    --group Wallpaper \
    --group org.kde.image \
    --group General \
    --key Image \
    "file://$WALL"

echo "Wallpaper copied."
