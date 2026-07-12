#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

cp -f "$REPO_DIR/.config/kwinrc" "$HOME/.config/" || true
cp -f "$REPO_DIR/.config/kwinrulesrc" "$HOME/.config/" || true

EFFECTS_SRC="$REPO_DIR/.local/share/kwin/effects"
SCRIPTS_SRC="$REPO_DIR/.local/share/kwin/scripts"

if [[ -d "$EFFECTS_SRC" ]]; then
    echo "Installing KWin effects..."
    for effect in "$EFFECTS_SRC"/*/; do
        name="$(basename "$effect")"
        if kpackagetool6 --type=KWin/Effect --list 2>/dev/null | grep -q "$name"; then
            echo "  Upgrading $name..."
            kpackagetool6 --type=KWin/Effect --upgrade "$effect" 2>/dev/null || true
        else
            echo "  Installing $name..."
            kpackagetool6 --type=KWin/Effect --install "$effect" 2>/dev/null || true
        fi
    done
fi

if [[ -d "$SCRIPTS_SRC" ]]; then
    echo "Installing KWin scripts..."
    for script in "$SCRIPTS_SRC"/*/; do
        name="$(basename "$script")"
        if kpackagetool6 --type=KWin/Script --list 2>/dev/null | grep -q "$name"; then
            echo "  Upgrading $name..."
            kpackagetool6 --type=KWin/Script --upgrade "$script" 2>/dev/null || true
        else
            echo "  Installing $name..."
            kpackagetool6 --type=KWin/Script --install "$script" 2>/dev/null || true
        fi
    done
fi

echo "Reloading KWin..."
qdbus org.kde.KWin /KWin org.kde.KWin.reloadConfig >/dev/null 2>&1 || true
