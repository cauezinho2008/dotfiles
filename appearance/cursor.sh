#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

CURSOR_NAME="BreezeX-Black"
CURSOR_SIZE=40
CURSOR_DIR="$HOME/.local/share/icons/$CURSOR_NAME"
GITHUB_REPO="ful1e5/BreezeX_Cursor"
GITHUB_API="https://api.github.com/repos/$GITHUB_REPO/releases/latest"
XDG_ENV_DIR="$HOME/.config/environment.d"

# ── 1. Download & install cursor theme ───────────────────────
echo "Downloading and installing $CURSOR_NAME..."

if [[ -d "$CURSOR_DIR" && -f "$CURSOR_DIR/index.theme" ]]; then
    echo "  Already installed at $CURSOR_DIR"
else
    TMPDIR="$(mktemp -d)"
    trap 'rm -rf "$TMPDIR"' EXIT

    DL_URL=$(curl -sL "$GITHUB_API" \
        | python3 -c "import sys,json; assets=json.load(sys.stdin).get('assets',[]); print(next((a['browser_download_url'] for a in assets if a['name']=='$CURSOR_NAME.tar.xz'),''))" 2>/dev/null) || true

    if [[ -z "$DL_URL" ]]; then
        echo "Failed to get download URL for $CURSOR_NAME"
        exit 1
    fi

    curl -sL -o "$TMPDIR/$CURSOR_NAME.tar.xz" "$DL_URL"
    mkdir -p "$HOME/.local/share/icons"
    tar -xf "$TMPDIR/$CURSOR_NAME.tar.xz" -C "$HOME/.local/share/icons/"
    echo "  Installed to $HOME/.local/share/icons/"
fi

# System-wide install (optional - requires sudo)
SYS_CURSOR_DIR="/usr/share/icons/$CURSOR_NAME"
if [[ ! -d "$SYS_CURSOR_DIR" ]]; then
    echo "  Installing system-wide to $SYS_CURSOR_DIR..."
    if [[ "$EUID" -eq 0 ]]; then
        mkdir -p "/usr/share/icons"
        cp -r "$HOME/.local/share/icons/$CURSOR_NAME" "/usr/share/icons/"
        gtk-update-icon-cache -f -t "/usr/share/icons/$CURSOR_NAME" 2>/dev/null || true
    elif sudo -n true 2>/dev/null; then
        sudo mkdir -p "/usr/share/icons"
        sudo cp -r "$HOME/.local/share/icons/$CURSOR_NAME" "/usr/share/icons/"
        sudo gtk-update-icon-cache -f -t "/usr/share/icons/$CURSOR_NAME" 2>/dev/null || true
    else
        echo "  (Skipping system-wide install - requires sudo. Run with sudo or as root for system-wide.)"
    fi
fi

# Set system-wide default cursor
if [[ "$EUID" -eq 0 ]]; then
    mkdir -p /usr/share/icons/default
    tee /usr/share/icons/default/index.theme >/dev/null <<SYS
[Icon Theme]
Inherits=$CURSOR_NAME
SYS
elif sudo -n true 2>/dev/null; then
    sudo mkdir -p /usr/share/icons/default
    sudo tee /usr/share/icons/default/index.theme >/dev/null <<SYS
[Icon Theme]
Inherits=$CURSOR_NAME
SYS
else
    echo "  (Skipping system-wide default - requires sudo)"
fi

gtk-update-icon-cache -f -t "$CURSOR_DIR" 2>/dev/null || true

# ── 2. KDE Plasma (kcminputrc + kdedefaults) ──────────────────
echo "Applying to KDE Plasma..."

mkdir -p "$HOME/.config/kdedefaults"
kwriteconfig6 --file "$HOME/.config/kdedefaults/kcminputrc" --group Mouse --key cursorTheme "$CURSOR_NAME"
kwriteconfig6 --file "$HOME/.config/kdedefaults/kcminputrc" --group Mouse --key cursorSize "$CURSOR_SIZE"

# Apply to current user config too
# Enable NumLock on startup
kwriteconfig6 --file "$HOME/.config/kcminputrc" --group Keyboard --key NumLock "1"
kwriteconfig6 --file "$HOME/.config/kdedefaults/kcminputrc" --group Keyboard --key NumLock "1"
kwriteconfig6 --file "$HOME/.config/kcminputrc" --group Mouse --key cursorTheme "$CURSOR_NAME"
kwriteconfig6 --file "$HOME/.config/kcminputrc" --group Mouse --key cursorSize "$CURSOR_SIZE"

# ── 3. klaunchrc (copy from repo) ────────────────────────────
echo "Copying klaunchrc..."
cp "$REPO_DIR/.config/klaunchrc" "$HOME/.config/klaunchrc"
echo "  Applied launch feedback settings"

# ── 4. GTK 3 ──────────────────────────────────────────────────
GTK3="$HOME/.config/gtk-3.0/settings.ini"
mkdir -p "$(dirname "$GTK3")"
{
    echo "[Settings]"
    echo "gtk-cursor-theme-name = $CURSOR_NAME"
    echo "gtk-cursor-theme-size = $CURSOR_SIZE"
} > "$GTK3"
echo "Applied GTK 3 cursor settings"

# ── 5. GTK 4 ──────────────────────────────────────────────────
GTK4="$HOME/.config/gtk-4.0/settings.ini"
mkdir -p "$(dirname "$GTK4")"
{
    echo "[Settings]"
    echo "gtk-cursor-theme-name=$CURSOR_NAME"
    echo "gtk-cursor-theme-size=$CURSOR_SIZE"
} > "$GTK4"
echo "Applied GTK 4 cursor settings"

# ── 6. GSettings (GNOME/GTK apps) ────────────────────────────
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_NAME" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE" 2>/dev/null || true
    echo "Applied GSettings cursor settings"
fi

# ── 7. X11 / XWayland (.Xresources + autostart) ──────────────
XR="$HOME/.Xresources"
mkdir -p "$(dirname "$XR")"
sed -i '/^Xcursor\.theme:/d; /^Xcursor\.size:/d' "$XR" 2>/dev/null || true
cat >> "$XR" << XEOF
Xcursor.theme: $CURSOR_NAME
Xcursor.size: $CURSOR_SIZE
XEOF

# Merge now if XWayland running
if command -v xrdb &>/dev/null; then
    xrdb -merge "$XR" 2>/dev/null && echo "  Merged into running XWayland" || echo "  Will load on next login"
fi

# Autostart for XWayland
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/xresources-load.desktop" << AUTOEOF
[Desktop Entry]
Type=Application
Name=Load Xresources
Exec=sh -c "xrdb -merge $XR"
X-KDE-autostart-phase=2
NoDisplay=true
AUTOEOF

echo "Applied X11 cursor settings"

# ── 8. Wayland environment.d (persists on next login) ─────────
mkdir -p "$XDG_ENV_DIR"
cat > "$XDG_ENV_DIR/cursor.conf" << ENV
XCURSOR_THEME=$CURSOR_NAME
XCURSOR_SIZE=$CURSOR_SIZE
ENV
echo "Applied Wayland environment variables"

# ── Helper: check if gdbus output indicates true ──────────────
is_true() {
    [[ "$1" == *"<true>"* ]]
}

# ── 9. Disable mouse acceleration (mice only) ─────────────────
echo "Disabling mouse acceleration for mice..."

# KDE config
kwriteconfig6 --file "$HOME/.config/kcminputrc" --group Mouse --key PointerAccelerationProfile "1" --notify
kwriteconfig6 --file "$HOME/.config/kcminputrc" --group Mouse --key PointerAcceleration "0.000" --notify
kwriteconfig6 --file "$HOME/.config/kdedefaults/kcminputrc" --group Mouse --key PointerAccelerationProfile "1"
kwriteconfig6 --file "$HOME/.config/kdedefaults/kcminputrc" --group Mouse --key PointerAcceleration "0.000"

# Update existing Libinput device sections (mice only - skip touchpads)
KCM="$HOME/.config/kcminputrc"
if [[ -f "$KCM" ]]; then
    python3 - "$KCM" << 'PYEOF'
import sys, configparser
cfg = configparser.ConfigParser(strict=False)
cfg.optionxform = str
cfg.read(sys.argv[1])
changed = False
for section in cfg.sections():
    if section.startswith("Libinput"):
        # Only apply to mice, not touchpads (touchpads have NaturalScroll)
        if cfg.get(section, "NaturalScroll", fallback=None) is None:
            if cfg.get(section, "PointerAccelerationProfile", fallback=None) != "1":
                cfg.set(section, "PointerAccelerationProfile", "1")
                changed = True
            if cfg.get(section, "PointerAcceleration", fallback=None) != "0.000":
                cfg.set(section, "PointerAcceleration", "0.000")
                changed = True
if changed:
    with open(sys.argv[1], "w") as f:
        cfg.write(f)
PYEOF
fi

# GNOME/GTK stack
command -v gsettings &>/dev/null && \
    gsettings set org.gnome.desktop.peripherals.mouse accel-profile 'flat' 2>/dev/null || true

# KWin D-Bus (Wayland) - only for pointer devices that are NOT touchpads
if command -v qdbus6 &>/dev/null; then
    for dev in $(qdbus6 org.kde.KWin 2>/dev/null | grep '/InputDevice/event'); do
        pointer=$(gdbus call --session --dest org.kde.KWin --object-path "$dev" \
            --method org.freedesktop.DBus.Properties.Get \
            org.kde.KWin.InputDevice pointer 2>/dev/null)
        touchpad=$(gdbus call --session --dest org.kde.KWin --object-path "$dev" \
            --method org.freedesktop.DBus.Properties.Get \
            org.kde.KWin.InputDevice touchpad 2>/dev/null)
        if is_true "$pointer" && ! is_true "$touchpad"; then
            gdbus call --session --dest org.kde.KWin --object-path "$dev" \
                --method org.freedesktop.DBus.Properties.Set \
                org.kde.KWin.InputDevice pointerAccelerationProfileFlat "<true>" 2>/dev/null || true
            gdbus call --session --dest org.kde.KWin --object-path "$dev" \
                --method org.freedesktop.DBus.Properties.Set \
                org.kde.KWin.InputDevice pointerAccelerationProfileAdaptive "<false>" 2>/dev/null || true
            gdbus call --session --dest org.kde.KWin --object-path "$dev" \
                --method org.freedesktop.DBus.Properties.Set \
                org.kde.KWin.InputDevice pointerAcceleration "<0.0>" 2>/dev/null || true
        fi
    done
fi

echo "Disabled mouse acceleration for mice"

# ── 10. Enable natural scrolling for touchpads ────────────────
echo "Enabling natural scrolling for touchpads..."

# KDE config - apply to existing touchpad sections
if [[ -f "$KCM" ]]; then
    python3 - "$KCM" << 'PYEOF'
import sys, configparser
cfg = configparser.ConfigParser(strict=False)
cfg.optionxform = str
cfg.read(sys.argv[1])
changed = False
for section in cfg.sections():
    if section.startswith("Libinput"):
        # Touchpads typically have NaturalScroll setting
        if cfg.get(section, "NaturalScroll", fallback=None) is not None:
            if cfg.get(section, "NaturalScroll", fallback=None) != "true":
                cfg.set(section, "NaturalScroll", "true")
                changed = True
if changed:
    with open(sys.argv[1], "w") as f:
        cfg.write(f)
PYEOF
fi

# KWin D-Bus (Wayland) - only for touchpads
if command -v qdbus6 &>/dev/null; then
    for dev in $(qdbus6 org.kde.KWin 2>/dev/null | grep '/InputDevice/event'); do
        touchpad=$(gdbus call --session --dest org.kde.KWin --object-path "$dev" \
            --method org.freedesktop.DBus.Properties.Get \
            org.kde.KWin.InputDevice touchpad 2>/dev/null)
        if is_true "$touchpad"; then
            gdbus call --session --dest org.kde.KWin --object-path "$dev" \
                --method org.freedesktop.DBus.Properties.Set \
                org.kde.KWin.InputDevice naturalScroll "<true>" 2>/dev/null || true
        fi
    done
fi

echo "Enabled natural scrolling for touchpads"

# ── 11. Disable shake cursor (accessibility) ──────────────────
kwriteconfig6 --file "$HOME/.config/kwinrc" --group Plugins --key shakecursorEnabled "false"
echo "Disabled shake cursor"

echo "Cursor setup complete: $CURSOR_NAME @ ${CURSOR_SIZE}px"
