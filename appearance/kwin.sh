#!/usr/bin/env bash
set -uo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

cp -f "$REPO_DIR/.config/kwinrc" "$HOME/.config/" || true
cp -f "$REPO_DIR/.config/kwinrulesrc" "$HOME/.config/" || true

if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
    # Safe on Wayland
    qdbus org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true

    # Reload effects without replacing compositor
    qdbus org.kde.KWin /KWin org.kde.KWin.reloadConfig >/dev/null 2>&1 || true

else
    # X11 can safely replace
    qdbus org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
    kwin_x11 --replace >/dev/null 2>&1 &
    disown || true
fi
