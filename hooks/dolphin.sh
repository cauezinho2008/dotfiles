#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

[[ -f "$REPO_DIR/.config/dolphinrc" ]] &&
    cp -a "$REPO_DIR/.config/dolphinrc" "$HOME/.config/"

[[ -d "$REPO_DIR/.local/share/dolphin" ]] &&
    cp -a "$REPO_DIR/.local/share/dolphin" "$HOME/.local/share/"

[[ -d "$REPO_DIR/.local/share/kio/servicemenus" ]] &&
    cp -a "$REPO_DIR/.local/share/kio/servicemenus" "$HOME/.local/share/kio/"

[[ -d "$REPO_DIR/.local/share/kxmlgui5/dolphin" ]] &&
    cp -a "$REPO_DIR/.local/share/kxmlgui5/dolphin" "$HOME/.local/share/kxmlgui5/"

[[ -f "$REPO_DIR/.local/state/dolphinstaterc" ]] &&
    cp -a "$REPO_DIR/.local/state/dolphinstaterc" "$HOME/.local/state/"

[[ -f "$REPO_DIR/.local/share/user-places.xbel" ]] &&
    sed "s|\$HOME|$HOME|g" "$REPO_DIR/.local/share/user-places.xbel" > "$HOME/.local/share/user-places.xbel"

rm -f "$HOME/.cache/kxmlgui5/dolphin"* "$HOME/.cache/kxmlgui6/dolphin"*

pkill dolphin 2>/dev/null || true
