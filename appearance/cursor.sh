#!/usr/bin/env bash
set -euo pipefail

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

THEME="BreezeX-Black"
URL="https://github.com/ful1e5/BreezeX_Cursor/releases/download/v2.0.1/BreezeX-Black.tar.xz"

clear

gum style \
    --foreground 39 \
    --bold \
    --align center \
"Install Cursor"

echo

gum style \
    --foreground 33 \
    --align center \
"This will install and apply $THEME system-wide."

echo
gum confirm "Continue?" || exit 0

# ==========================================================
# Download
# ==========================================================

echo
gum style --foreground 39 "Downloading cursor theme..."
echo

curl -# -L "$URL" -o "$TMP/cursor.tar.xz"

echo
gum style --foreground 39 "Extracting..."
echo

tar -xJf "$TMP/cursor.tar.xz" -C "$TMP"

# ==========================================================
# Install
# ==========================================================


# ==========================================================
# KDE
# ==========================================================

kwriteconfig6 \
    --file kdeglobals \
    --group Icons \
    --key cursorTheme \
    "$THEME"

kwriteconfig6 \
    --file kdeglobals \
    --group Icons \
    --key cursorSize \
    24

# ==========================================================
# GTK (3/4)
# ==========================================================

mkdir -p "$HOME/.icons/default"

cat > "$HOME/.icons/default/index.theme" <<EOF
[Icon Theme]
Inherits=$THEME
EOF

mkdir -p "$HOME/.config/gtk-3.0"
mkdir -p "$HOME/.config/gtk-4.0"

for gtk in \
    "$HOME/.config/gtk-3.0/settings.ini" \
    "$HOME/.config/gtk-4.0/settings.ini"
do
    touch "$gtk"

    sed -i '/gtk-cursor-theme-name/d' "$gtk"
    sed -i '/gtk-cursor-theme-size/d' "$gtk"

    echo "gtk-cursor-theme-name=$THEME" >> "$gtk"
    echo "gtk-cursor-theme-size=24" >> "$gtk"
done

# ==========================================================
# X11 / XWayland
# ==========================================================

cat > "$HOME/.Xresources" <<EOF
Xcursor.theme: $THEME
Xcursor.size: 24
EOF

xrdb "$HOME/.Xresources" >/dev/null 2>&1 || true

# ==========================================================
# Reload live
# ==========================================================

qdbus org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
kquitapp5 plasmashell >/dev/null 2>&1 || true
kstart5 plasmashell >/dev/null 2>&1 || true

echo
gum style \
    --foreground 82 \
    --align center \
"Cursor applied: $THEME"
echo
