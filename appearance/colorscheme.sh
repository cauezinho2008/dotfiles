#!/usr/bin/env bash
set -uo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/share/color-schemes"

cp -f "$REPO_DIR/.config/kdeglobals" "$HOME/.config/" || true
cp -a "$REPO_DIR/.local/share/color-schemes/." \
      "$HOME/.local/share/color-schemes/" || true

SCHEME="$(awk -F= '/^ColorScheme=/{print $2}' "$HOME/.config/kdeglobals" 2>/dev/null || true)"

if [[ -n "$SCHEME" ]]; then
    plasma-apply-colorscheme "$SCHEME" >/dev/null 2>&1 || true
fi

qdbus org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true

echo "Colorscheme applied."
read -rp "Press Enter to continue..."
