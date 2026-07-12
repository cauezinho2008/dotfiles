#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

cp -f "$REPO_DIR/.config/kwinrc" "$HOME/.config/" || true
cp -f "$REPO_DIR/.config/kwinrulesrc" "$HOME/.config/" || true

# KDE Store IDs for effects and scripts
# Format: name:store_id
KWIN_EFFECTS=(
    "bouncingPopups:2350410"
    "bouncingWindows:2350409"
)

KWIN_SCRIPTS=(
    "center-new-windows:2162132"
)

install_kns() {
    local type="$1" id="$2" name="$3"

    local tmpdir
    tmpdir="$(mktemp -d)"
    local pkgfile="$tmpdir/package"

    local dlurl
    dlurl="$(curl -sL "https://api.opendesktop.org/v1/content/data/$id" \
        | python3 -c "import sys,json; print(json.load(sys.stdin)['downloadurl'])" 2>/dev/null)" || true

    if [[ -z "$dlurl" ]]; then
        echo "  Failed to get download URL for $name (ID: $id)"
        rm -rf "$tmpdir"
        return
    fi

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

echo "Installing KWin effects from KDE Store..."
for entry in "${KWIN_EFFECTS[@]}"; do
    name="${entry%%:*}"
    id="${entry##*:}"
    install_kns "Effect" "$id" "$name"
done

echo "Installing KWin scripts from KDE Store..."
for entry in "${KWIN_SCRIPTS[@]}"; do
    name="${entry%%:*}"
    id="${entry##*:}"
    install_kns "Script" "$id" "$name"
done

echo "Reloading KWin..."
qdbus org.kde.KWin /KWin org.kde.KWin.reloadConfig >/dev/null 2>&1 || true
