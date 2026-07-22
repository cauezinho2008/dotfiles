#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# kdenliverc
mkdir -p "$HOME/.config"
[[ -f "$REPO_DIR/.config/kdenlive/kdenliverc" ]] &&
    sed "s|\$HOME|$HOME|g" "$REPO_DIR/.config/kdenlive/kdenliverc" > "$HOME/.config/kdenliverc"

# layouts, transcoding, profiles
[[ -d "$REPO_DIR/.local/share/kdenlive" ]] &&
    cp -a "$REPO_DIR/.local/share/kdenlive" "$HOME/.local/share/"

# menu/toolbar layout
mkdir -p "$HOME/.local/share/kxmlgui5/kdenlive"
[[ -f "$REPO_DIR/.local/share/kxmlgui5/kdenlive/kdenliveui.rc" ]] &&
    cp -a "$REPO_DIR/.local/share/kxmlgui5/kdenlive/kdenliveui.rc" "$HOME/.local/share/kxmlgui5/kdenlive/"
