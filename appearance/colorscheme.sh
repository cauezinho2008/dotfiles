#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME_NAME="BreezeDarker"
SCHEME_FILE="$SCHEME_NAME.colors"

mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/share/color-schemes"

echo "Installing color schemes..."

cp -af "$REPO_DIR/.local/share/color-schemes/." \
       "$HOME/.local/share/color-schemes/"

SCHEME_HASH=$(sha1sum "$HOME/.local/share/color-schemes/$SCHEME_FILE" | awk '{print $1}')

kwriteconfig6 --file "$HOME/.config/kdeglobals" --group General --key ColorScheme "$SCHEME_NAME"
kwriteconfig6 --file "$HOME/.config/kdeglobals" --group General --key ColorSchemeHash "$SCHEME_HASH"

mkdir -p "$HOME/.config/kdedefaults"
kwriteconfig6 --file "$HOME/.config/kdedefaults/kdeglobals" --group General --key ColorScheme "$SCHEME_NAME"

echo "Applying $SCHEME_NAME..."

plasma-apply-colorscheme "$SCHEME_NAME" >/dev/null 2>&1 || true

echo "Color scheme applied."
