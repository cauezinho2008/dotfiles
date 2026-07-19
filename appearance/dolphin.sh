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

# Keep Places Remote (Network) section hidden
kwriteconfig6 --file kdeglobals --group "KFileDialog Settings" --key ShowRemote false

# Remove ShowRecentFiles key from kdeglobals (was interfering with xbel's withRecentlyUsed)
KCM="$HOME/.config/kdeglobals"
if [[ -f "$KCM" ]]; then
    python3 - "$KCM" << 'PYEOF'
import sys, configparser
cfg = configparser.ConfigParser(strict=False)
cfg.optionxform = str
cfg.read(sys.argv[1])
changed = False
if cfg.has_section("KFileDialog Settings"):
    if cfg.remove_option("KFileDialog Settings", "ShowRecentFiles"):
        changed = True
if changed:
    with open(sys.argv[1], "w") as f:
        cfg.write(f)
PYEOF
fi

# ── Clear toolbar cache & restart ──────────────────────────

rm -f "$HOME/.cache/kxmlgui5/dolphin"* "$HOME/.cache/kxmlgui6/dolphin"*

pkill dolphin 2>/dev/null || true