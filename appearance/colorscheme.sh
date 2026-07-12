#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/share/color-schemes"

echo "Installing color schemes..."

cp -af "$REPO_DIR/.local/share/color-schemes/." \
       "$HOME/.local/share/color-schemes/"

cp -f "$REPO_DIR/.config/kdeglobals" \
      "$HOME/.config/kdeglobals"

SCHEME="$(
    awk -F= '/^ColorScheme=/{print $2}' \
    "$HOME/.config/kdeglobals"
)"

if [[ -n "$SCHEME" ]]; then
    echo "Applying $SCHEME..."

    # Make sure the value is written
    kwriteconfig6 \
        --file "$HOME/.config/kdeglobals" \
        --group General \
        --key ColorScheme \
        "$SCHEME"

    # Apply live
    plasma-apply-colorscheme "$SCHEME" >/dev/null 2>&1 || true
fi

# Reload KWin decorations/colors
#qdbus org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || #true
#
# Ask Plasma to reload its configuration
#if qdbus org.kde.plasmashell >/dev/null 2>&1; then
#    qdbus org.kde.plasmashell \
#        /PlasmaShell \
#        org.kde.PlasmaShell.reloadConfig >/dev/null 2>&1 #|| true
#fi

echo
echo "Color scheme applied."
