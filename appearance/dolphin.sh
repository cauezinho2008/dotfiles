#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOME_DIR="$HOME"

# ── dolphinrc ──────────────────────────────────────────────

[[ -f "$REPO_DIR/.config/dolphinrc" ]] &&
    cp -a "$REPO_DIR/.config/dolphinrc" "$HOME/.config/"

# ── dolphin data dir ───────────────────────────────────────

[[ -d "$REPO_DIR/.local/share/dolphin" ]] &&
    cp -a "$REPO_DIR/.local/share/dolphin" "$HOME/.local/share/"

# ── servicemenus ───────────────────────────────────────────

[[ -d "$REPO_DIR/.local/share/kio/servicemenus" ]] &&
    cp -a "$REPO_DIR/.local/share/kio/servicemenus" "$HOME/.local/share/kio/"

# ── kxmlgui (toolbar) ──────────────────────────────────────

[[ -d "$REPO_DIR/.local/share/kxmlgui5/dolphin" ]] &&
    cp -a "$REPO_DIR/.local/share/kxmlgui5/dolphin" "$HOME/.local/share/kxmlgui5/"

# ── dolphinstaterc ─────────────────────────────────────────

[[ -f "$REPO_DIR/.local/state/dolphinstaterc" ]] &&
    cp -a "$REPO_DIR/.local/state/dolphinstaterc" "$HOME/.local/state/"

# ── Places panel (no Recent/Network) ──────────────────────

PLACES_FILE="$HOME/.local/share/user-places.xbel"
mkdir -p "$(dirname "$PLACES_FILE")"

sed "s|\$HOME|$HOME|g" "$REPO_DIR/.local/share/user-places.xbel" > "$PLACES_FILE"

# Hide Recent and Remote (Network) from Places panel
kwriteconfig6 --file kdeglobals --group "KFileDialog Settings" --key ShowRecentFiles false
kwriteconfig6 --file kdeglobals --group "KFileDialog Settings" --key ShowRemote false

# ── Clear toolbar cache & restart ──────────────────────────

rm -f "$HOME/.cache/kxmlgui5/dolphin"* "$HOME/.cache/kxmlgui6/dolphin"*

pkill dolphin 2>/dev/null || true
