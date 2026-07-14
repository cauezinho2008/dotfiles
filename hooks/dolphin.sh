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

pkill dolphin 2>/dev/null || true
