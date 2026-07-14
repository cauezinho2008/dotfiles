#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# ── Disable file indexing (Baloo) ────────────────────────────

cp -f "$REPO_DIR/.config/baloofilerc" "$HOME/.config/"
echo "Disabled Baloo file indexing"

# ── KRunner plugins ──────────────────────────────────────────

cp -f "$REPO_DIR/.config/krunnerrc" "$HOME/.config/"
echo "Applied KRunner search plugins"

# ── Recent documents ─────────────────────────────────────────

kwriteconfig6 --file "$HOME/.config/kdeglobals" --group KDE --key RecentDocuments "false"
echo "Disabled recent documents"
