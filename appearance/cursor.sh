#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

CURSOR_NAME="BreezeX-Black"
CURSOR_SIZE=40
CURSOR_DIR="$HOME/.local/share/icons/$CURSOR_NAME"
GITHUB_REPO="ful1e5/BreezeX_Cursor"
GITHUB_API="https://api.github.com/repos/$GITHUB_REPO/releases/latest"
XDG_ENV_DIR="$HOME/.config/environment.d"

# ── Download & install ───────────────────────────────────────

if [[ -d "$CURSOR_DIR" && -f "$CURSOR_DIR/index.theme" ]]; then
    echo "Cursor $CURSOR_NAME already installed at $CURSOR_DIR"
else
    echo "Downloading $CURSOR_NAME from GitHub..."

    TMPDIR="$(mktemp -d)"
    trap 'rm -rf "$TMPDIR"' EXIT

    DL_URL=$(curl -sL "$GITHUB_API" \
        | python3 -c "import sys,json; assets=json.load(sys.stdin).get('assets',[]); print(next((a['browser_download_url'] for a in assets if a['name']=='$CURSOR_NAME.tar.xz'),''))" 2>/dev/null) || true

    if [[ -z "$DL_URL" ]]; then
        echo "Failed to get download URL for $CURSOR_NAME"
        exit 1
    fi

    curl -sL -o "$TMPDIR/$CURSOR_NAME.tar.xz" "$DL_URL"

    echo "Installing to $HOME/.local/share/icons/..."
    mkdir -p "$HOME/.local/share/icons"
    tar -xf "$TMPDIR/$CURSOR_NAME.tar.xz" -C "$HOME/.local/share/icons/"
fi

# ── Update icon cache ────────────────────────────────────────

echo "Updating icon cache..."
gtk-update-icon-cache -f -t "$CURSOR_DIR" 2>/dev/null || true

# ── KDE Plasma ───────────────────────────────────────────────

echo "Applying to KDE Plasma..."

mkdir -p "$HOME/.config/kdedefaults"
kwriteconfig6 --file "$HOME/.config/kdedefaults/kcminputrc" --group Mouse --key cursorTheme "$CURSOR_NAME"
kwriteconfig6 --file "$HOME/.config/kdedefaults/kcminputrc" --group Mouse --key cursorSize "$CURSOR_SIZE"

# ── GTK 3 ────────────────────────────────────────────────────

GTK3="$HOME/.config/gtk-3.0/settings.ini"
mkdir -p "$(dirname "$GTK3")"

if [[ -f "$GTK3" ]]; then
    sed -i "s/^gtk-cursor-theme-name.*/gtk-cursor-theme-name = $CURSOR_NAME/" "$GTK3"
    sed -i "s/^gtk-cursor-theme-size.*/gtk-cursor-theme-size = $CURSOR_SIZE/" "$GTK3"
else
    cat > "$GTK3" << EOF
[Settings]
gtk-cursor-theme-name = $CURSOR_NAME
gtk-cursor-theme-size = $CURSOR_SIZE
EOF
fi

echo "Applied GTK 3 cursor settings"

# ── GTK 4 ────────────────────────────────────────────────────

GTK4="$HOME/.config/gtk-4.0/settings.ini"
mkdir -p "$(dirname "$GTK4")"

if [[ -f "$GTK4" ]]; then
    sed -i "s/^gtk-cursor-theme-name.*/gtk-cursor-theme-name=$CURSOR_NAME/" "$GTK4"
    sed -i "s/^gtk-cursor-theme-size.*/gtk-cursor-theme-size=$CURSOR_SIZE/" "$GTK4"
else
    cat > "$GTK4" << EOF
[Settings]
gtk-cursor-theme-name=$CURSOR_NAME
gtk-cursor-theme-size=$CURSOR_SIZE
EOF
fi

echo "Applied GTK 4 cursor settings"

# ── Xresources (X11) ────────────────────────────────────────

XR="$HOME/.Xresources"
mkdir -p "$(dirname "$XR")"

# Remove old Xcursor lines, then append
if [[ -f "$XR" ]]; then
    sed -i '/^Xcursor\.theme:/d; /^Xcursor\.size:/d' "$XR"
fi
cat >> "$XR" << EOF
Xcursor.theme: $CURSOR_NAME
Xcursor.size: $CURSOR_SIZE
EOF

command -v xrdb &>/dev/null && xrdb -merge "$XR"

echo "Applied X11 cursor settings"

# ── Wayland environment.d ────────────────────────────────────

mkdir -p "$XDG_ENV_DIR"
cat > "$XDG_ENV_DIR/cursor.conf" << EOF
XCURSOR_THEME=$CURSOR_NAME
XCURSOR_SIZE=$CURSOR_SIZE
EOF

echo "Applied Wayland environment variables"

# ── Hyprland ─────────────────────────────────────────────────

HYPRLAND="$HOME/.config/hypr/hyprland.conf"
if [[ -f "$HYPRLAND" ]]; then
    sed -i '/^cursor=/d' "$HYPRLAND"
    echo "cursor=$CURSOR_NAME $CURSOR_SIZE" >> "$HYPRLAND"
    echo "Applied Hyprland cursor settings"
fi

# ── System-wide default (optional) ──────────────────────────

if [[ "$EUID" -eq 0 ]]; then
    DEFAULT_DIR="/usr/share/icons/default"
    mkdir -p "$DEFAULT_DIR"
    cat > "$DEFAULT_DIR/index.theme" << EOF
[Icon Theme]
Inherits=$CURSOR_NAME
EOF
    echo "Applied system-wide cursor default"
fi
echo "Cursor setup complete: $CURSOR_NAME @ ${CURSOR_SIZE}px"
