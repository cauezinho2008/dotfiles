#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

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

    dlurl=$(curl -sL "https://api.opendesktop.org/ocs/v1/content/data/$id?format=json" \
        | python3 -c "import sys,json; print(json.load(sys.stdin)['data'][0]['downloadlink1'])" 2>/dev/null) || true

    if [[ -z "$dlurl" ]]; then
        echo "  Failed to get download URL for $name (ID: $id)"
        rm -rf "$tmpdir"
        return
    fi

    echo "  Downloading $name..."
    curl -sL -o "$pkgfile" "$dlurl"

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

