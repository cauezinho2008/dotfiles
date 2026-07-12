#!/usr/bin/env bash
set -euo pipefail

FONT_NAME="ProFont IIx Nerd Font Mono"
FONT_SIZE=10
FONT_DIR="$HOME/.local/share/fonts"
NERDFONTS_API="https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest"

# ── Download & install ───────────────────────────────────────

INSTALLED=false
if fc-list ":family=${FONT_NAME}" 2>/dev/null | grep -qi .; then
    echo "Font '$FONT_NAME' already installed"
else
    echo "Downloading $FONT_NAME from Nerd Fonts..."

    TMPDIR="$(mktemp -d)"
    trap 'rm -rf "$TMPDIR"' EXIT

    DL_URL=$(curl -sL "$NERDFONTS_API" \
        | python3 -c "import sys,json; assets=json.load(sys.stdin).get('assets',[]); print(next((a['browser_download_url'] for a in assets if a['name']=='ProFont.tar.xz'),''))" 2>/dev/null) || true

    if [[ -z "$DL_URL" ]]; then
        echo "Failed to get download URL for ProFont"
        exit 1
    fi

    curl -sL -o "$TMPDIR/ProFont.tar.xz" "$DL_URL"

    echo "Installing to $FONT_DIR..."
    mkdir -p "$FONT_DIR"
    tar -xf "$TMPDIR/ProFont.tar.xz" -C "$FONT_DIR" --wildcards '*.ttf' 2>/dev/null || \
        tar -xf "$TMPDIR/ProFont.tar.xz" -C "$FONT_DIR" 2>/dev/null || true
    # Clean up non-font files if any got through
    rm -f "$FONT_DIR/LICENSE" "$FONT_DIR/README.md" 2>/dev/null || true

    # Update font cache
    echo "Updating font cache..."
    fc-cache -f "$FONT_DIR" 2>/dev/null || true
    INSTALLED=true
fi

# ── KDE Plasma ───────────────────────────────────────────────

echo "Applying to KDE Plasma..."
kwriteconfig6 --file "$HOME/.config/kdeglobals" --group General --key font "$FONT_NAME,$FONT_SIZE,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,,0,0"
kwriteconfig6 --file "$HOME/.config/kdeglobals" --group General --key fixed "$FONT_NAME,$FONT_SIZE,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,,0,0"
kwriteconfig6 --file "$HOME/.config/kdeglobals" --group General --key menuFont "$FONT_NAME,$FONT_SIZE,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,,0,0"
kwriteconfig6 --file "$HOME/.config/kdeglobals" --group General --key toolBarFont "$FONT_NAME,$FONT_SIZE,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,,0,0"
kwriteconfig6 --file "$HOME/.config/kdeglobals" --group General --key smallestReadableFont "$FONT_NAME,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,,0,0"
kwriteconfig6 --file "$HOME/.config/kdeglobals" --group WM --key activeFont "$FONT_NAME,$FONT_SIZE,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,,0,0"

echo "Applied KDE font settings"

# ── GTK 4 ────────────────────────────────────────────────────

GTK4="$HOME/.config/gtk-4.0/settings.ini"
mkdir -p "$(dirname "$GTK4")"

if [[ -f "$GTK4" ]]; then
    sed -i "s/^gtk-font-name.*/gtk-font-name=$FONT_NAME,  $FONT_SIZE/" "$GTK4"
else
    cat > "$GTK4" << EOF
[Settings]
gtk-font-name=$FONT_NAME,  $FONT_SIZE
EOF
fi

echo "Applied GTK 4 font settings"

# ── Reload KDE config ────────────────────────────────────────

if command -v qdbus &>/dev/null && qdbus org.kde.KWin &>/dev/null 2>&1; then
    qdbus org.kde.KWin /KWin org.kde.KWin.reloadConfig 2>/dev/null || true
fi

systemctl --user daemon-reexec 2>/dev/null || true

echo "Font setup complete: $FONT_NAME @ ${FONT_SIZE}pt"
