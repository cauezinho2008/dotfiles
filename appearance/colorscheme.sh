#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME_NAME="BreezeDarker"
SCHEME_FILE="$SCHEME_NAME.colors"
SCHEME_PATH="$HOME/.local/share/color-schemes/$SCHEME_FILE"
KDE_GLOBALS="$HOME/.config/kdeglobals"

mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/share/color-schemes"

echo "Installing color scheme..."

cp -af "$REPO_DIR/.local/share/color-schemes/." "$HOME/.local/share/color-schemes/"

SCHEME_HASH=$(sha1sum "$SCHEME_PATH" | awk '{print $1}')

# Write color values via Python (handles nested sections like [Colors:Header][Inactive])
python3 - "$SCHEME_PATH" "$KDE_GLOBALS" "$SCHEME_NAME" "$SCHEME_HASH" << 'PYEOF'
import sys, configparser

src_file, dst_file, scheme_name, scheme_hash = sys.argv[1:]

src = configparser.ConfigParser(strict=False)
src.optionxform = str
src.read(src_file)

dst = configparser.ConfigParser(strict=False)
dst.optionxform = str
dst.read(dst_file)

# Remove stale color sections (preserve non-color keys in WM and KDE)
for section in list(dst.sections()):
    if section.startswith("Colors:") or section.startswith("ColorEffects:"):
        dst.remove_section(section)

# Write color sections from source (skip General, we handle it separately)
for section in src.sections():
    if section == "General":
        continue
    if not dst.has_section(section):
        dst.add_section(section)
    for key, value in src.items(section):
        dst.set(section, key, value)

# Set scheme name and hash
if not dst.has_section("General"):
    dst.add_section("General")
dst.set("General", "ColorScheme", scheme_name)
dst.set("General", "ColorSchemeHash", scheme_hash)

with open(dst_file, "w") as f:
    dst.write(f)
PYEOF

# Normalize KDE format: remove spaces around =
sed -i 's/ = /=/g' "$KDE_GLOBALS"

# Also write to kdedefaults so it survives first-time Plasma setup
mkdir -p "$HOME/.config/kdedefaults"
kwriteconfig6 --file "$HOME/.config/kdedefaults/kdeglobals" --group General --key ColorScheme "$SCHEME_NAME"

echo "Applying $SCHEME_NAME..."

if command -v plasma-apply-colorscheme &>/dev/null; then
    plasma-apply-colorscheme "$SCHEME_NAME"
fi

echo "Color scheme applied."

# --- GTK config ---

mkdir -p "$HOME/.config"

[[ -d "$REPO_DIR/.config/gtk-3.0" ]] &&
    cp -a "$REPO_DIR/.config/gtk-3.0" "$HOME/.config/"

[[ -d "$REPO_DIR/.config/gtk-4.0" ]] &&
    cp -a "$REPO_DIR/.config/gtk-4.0" "$HOME/.config/"

[[ -f "$REPO_DIR/.config/gtkrc" ]] &&
    cp -a "$REPO_DIR/.config/gtkrc" "$HOME/.config/"

gsettings set org.gnome.desktop.interface gtk-theme "Breeze" 2>/dev/null || true

# --- Application style ---

mkdir -p "$HOME/.config"
[[ -f "$REPO_DIR/.config/breezerc" ]] &&
    cp -a "$REPO_DIR/.config/breezerc" "$HOME/.config/"

kwriteconfig6 --file kwinrc --group MouseBindings --key CommandAllKey Alt
kwriteconfig6 --file kwinrc --group MouseBindings --key CommandAll1 Move
