#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WALLPAPER_DIR="$REPO_DIR/wallpapers"

mkdir -p "$HOME/Pictures/Wallpapers"

wallpaper="$(find "$WALLPAPER_DIR" -type f | head -n1)"

[[ -z "${wallpaper:-}" ]] && exit 0

cp -f "$wallpaper" "$HOME/Pictures/Wallpapers/"

final="$HOME/Pictures/Wallpapers/$(basename "$wallpaper")"

plasma-apply-wallpaperimage "$final" >/dev/null 2>&1 || true
