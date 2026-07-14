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

# ── Launch feedback ──────────────────────────────────────────

kwriteconfig6 --file "$HOME/.config/klaunchrc" --group FeedbackStyle --key FeedbackEnabled "true"
echo "Enabled launch feedback"

# ── Disable shake cursor ─────────────────────────────────────

kwriteconfig6 --file "$HOME/.config/kwinrc" --group Plugins --key shakecursorEnabled "false"
echo "Disabled shake cursor accessibility feature"

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

# ── GSettings (GNOME/GTK override for apps that ignore settings.ini) ──
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_NAME" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE" 2>/dev/null || true
    echo "Applied GSettings cursor settings"
fi

# ── Xresources (X11 / XWayland) ─────────────────────────────

XR="$HOME/.Xresources"
mkdir -p "$(dirname "$XR")"

if [[ -f "$XR" ]]; then
    sed -i '/^Xcursor\.theme:/d; /^Xcursor\.size:/d' "$XR"
fi
cat >> "$XR" << EOF
Xcursor.theme: $CURSOR_NAME
Xcursor.size: $CURSOR_SIZE
EOF

# Merge into XWayland if running; also write a script for autostart
if command -v xrdb &>/dev/null; then
    if xrdb -merge "$XR" 2>/dev/null; then
        echo "  Merged into running XWayland"
    else
        echo "  XWayland not ready yet, will load on next login"
    fi
fi

# Autostart helper to reload on XWayland start
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/xresources-load.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Load Xresources
Exec=sh -c "xrdb -merge $XR"
X-KDE-autostart-phase=2
NoDisplay=true
EOF

echo "Applied X11 cursor settings"

# ── Environment vars for current session ─────────────────────
export XCURSOR_THEME="$CURSOR_NAME"
export XCURSOR_SIZE="$CURSOR_SIZE"

# ── Wayland environment.d (persists on next login) ───────────
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
# ── Disable mouse acceleration ──────────────────────────────

echo "Disabling mouse acceleration..."

# Set Flat profile as default for future devices
kwriteconfig6 --file "$HOME/.config/kdedefaults/kcminputrc" --group Mouse --key PointerAccelerationProfile "1"
kwriteconfig6 --file "$HOME/.config/kdedefaults/kcminputrc" --group Mouse --key PointerAcceleration "0.000"

# Apply to all existing Libinput mouse devices in kcminputrc
KCM="$HOME/.config/kcminputrc"
if [[ -f "$KCM" ]]; then
    sed -i '/^\[Libinput/,/^\[/ s/^PointerAccelerationProfile=.*/PointerAccelerationProfile=1/' "$KCM"
    sed -i '/^\[Libinput/,/^\[/ s/^PointerAcceleration=.*/PointerAcceleration=0.000/' "$KCM"
fi

# gsettings for GNOME/GTK stack
command -v gsettings &>/dev/null && \
    gsettings set org.gnome.desktop.peripherals.mouse accel-profile 'flat' 2>/dev/null || true

# xinput for running XWayland
if command -v xinput &>/dev/null; then
    for dev in $(xinput list --id-only 2>/dev/null); do
        xinput --set-prop "$dev" "libinput Accel Profile Enabled" 0, 1 2>/dev/null || true
        xinput --set-prop "$dev" "libinput Accel Speed" 0 2>/dev/null || true
    done
fi

echo "Disabled mouse acceleration"

echo "Cursor setup complete: $CURSOR_NAME @ ${CURSOR_SIZE}px"
