#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Copy config files
cp -f "$REPO_DIR/.config/kwinrc" "$HOME/.config/" || true
cp -f "$REPO_DIR/.config/kwinrulesrc" "$HOME/.config/" || true

# KDE Store IDs for effects and scripts
KWIN_EFFECTS=(
    "bouncingPopups:2350410"
    "bouncingWindows:2350409"
)

KWIN_SCRIPTS=(
    "center-new-windows:2162132"
)

install_kns() {
    local type="$1" id="$2" name="$3"
    local tmpdir pkgfile dlurl

    tmpdir="$(mktemp -d)"
    pkgfile="$tmpdir/package"

    # Try multiple download URLs
    dlurl=$(curl -sL "https://api.opendesktop.org/ocs/v1/content/data/$id?format=json" \
        | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; print(next((x['downloadlink1'] for x in d if x.get('downloadlink1')), next((x['downloadlink2'] for x in d if x.get('downloadlink2')), '')))" 2>/dev/null) || true

    if [[ -z "$dlurl" ]]; then
        # Try alternative API endpoint
        dlurl=$(curl -sL "https://store.kde.org/api/content/data/$id?format=json" \
            | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; print(next((x['downloadlink1'] for x in d if x.get('downloadlink1')), next((x['downloadlink2'] for x in d if x.get('downloadlink2')), '')))" 2>/dev/null) || true
    fi

    if [[ -z "$dlurl" ]]; then
        echo "  Failed to get download URL for $name (ID: $id)"
        rm -rf "$tmpdir"
        return
    fi

    echo "  Downloading $name..."
    curl -sL -o "$pkgfile" "$dlurl" || {
        echo "  Download failed for $name"
        rm -rf "$tmpdir"
        return
    }

    if kpackagetool6 --type="KWin/$type" --list 2>/dev/null | grep -q "$name"; then
        echo "  Upgrading $name..."
        kpackagetool6 --type="KWin/$type" --upgrade "$pkgfile" 2>/dev/null || true
    else
        echo "  Installing $name..."
        kpackagetool6 --type="KWin/$type" --install "$pkgfile" 2>/dev/null || true
    fi

    rm -rf "$tmpdir"
}

enable_kwin_component() {
    local name="$1"
    kwriteconfig6 --file "$HOME/.config/kwinrc" --group Plugins --key "${name}Enabled" "true"
}

# --- Window decoration settings ---
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key BorderSize Normal
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ShowToolTips false

kwriteconfig6 --file kwinrc --group MouseBindings --key CommandAllKey Meta
kwriteconfig6 --file kwinrc --group MouseBindings --key CommandAll1 Move
kwriteconfig6 --file kwinrc --group MouseBindings --key CommandAll2 "Operations menu"
kwriteconfig6 --file kwinrc --group MouseBindings --key CommandAll3 Resize
kwriteconfig6 --file kwinrc --group MouseBindings --key CommandAllWheel "Maximize/Restore"

# --- Breeze decoration settings ---
kwriteconfig6 --file breezerc --group Windeco --key ButtonSize 2
kwriteconfig6 --file breezerc --group Windeco --key DrawBackgroundGradient true
kwriteconfig6 --file breezerc --group Windeco --key DrawHighlight true
kwriteconfig6 --file breezerc --group Windeco --key DrawInnerBorder true
kwriteconfig6 --file breezerc --group Windeco --key DrawOuterBorder false
kwriteconfig6 --file breezerc --group Windeco --key ShadowSize ShadowSmall
kwriteconfig6 --file breezerc --group Windeco --key TitleAlignment AlignCenterFullWidth
kwriteconfig6 --file breezerc --group Common --key OutlineCloseButton true
kwriteconfig6 --file breezerc --group Windeco --key DrawBorderOnMaximizedWindows false
kwriteconfig6 --file breezerc --group Windeco --key roundedCorners true
kwriteconfig6 --file breezerc --group Windeco --key ShadowStrength 255

# --- Global animation speed (affects menus, tray, minimize/maximize) ---
kwriteconfig6 --file kdeglobals --group KDE --key AnimationSpeed 1
kwriteconfig6 --file kwinrc --group Compositor --key AnimationSpeed 1

echo "Installing KWin effects from KDE Store..."
for entry in "${KWIN_EFFECTS[@]}"; do
    name="${entry%%:*}"
    id="${entry##*:}"
    install_kns "Effect" "$id" "$name"
    enable_kwin_component "$name"
done

echo "Installing KWin scripts from KDE Store..."
for entry in "${KWIN_SCRIPTS[@]}"; do
    name="${entry%%:*}"
    id="${entry##*:}"
    install_kns "Script" "$id" "$name"
    enable_kwin_component "$name"
done

echo "KWin config applied (animations, effects, scripts)."

# --- Skyler Animated Plasma Task Manager ---
if ! kpackagetool6 --type=Plasma/Applet --list 2>/dev/null | grep -q "org.kde.plasma.icontasks.skyler"; then
    echo "Installing Skyler Animated Plasma Task Manager..."
    tmpdir=$(mktemp -d)
    git clone https://github.com/SkyShadowHero/Animated-plasma-task.git "$tmpdir/Animated-plasma-task" 2>/dev/null || {
        echo "  Failed to clone Skyler task manager"
        rm -rf "$tmpdir"
    }
    if [[ -d "$tmpdir/Animated-plasma-task" ]]; then
        (
            cd "$tmpdir/Animated-plasma-task"
            rm -rf build
            mkdir build
            cd build
            cmake .. -DCMAKE_INSTALL_PREFIX=/usr >/dev/null 2>&1 && make -j$(nproc) >/dev/null 2>&1 && sudo make install >/dev/null 2>&1 && echo "  Skyler task manager installed"
        ) || echo "  Failed to build/install Skyler task manager"
        rm -rf "$tmpdir"
    fi
fi
