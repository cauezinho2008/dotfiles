#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$HOME/.config"

[[ -d "$REPO_DIR/.config/gtk-3.0" ]] &&
    cp -a "$REPO_DIR/.config/gtk-3.0" "$HOME/.config/"

[[ -d "$REPO_DIR/.config/gtk-4.0" ]] &&
    cp -a "$REPO_DIR/.config/gtk-4.0" "$HOME/.config/"

[[ -f "$REPO_DIR/.config/gtkrc" ]] &&
    cp -a "$REPO_DIR/.config/gtkrc" "$HOME/.config/"

gsettings set org.gnome.desktop.interface gtk-theme "Breeze" 2>/dev/null || true
