#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ARDIR="$HOME/.config/ardour9"

mkdir -p "$ARDIR"

for f in config ui_config instant.xml "my-adwaita_dark-ardour-9.7.colors" port_metadata; do
    src="$REPO_DIR/.config/ardour9/$f"
    [[ -f "$src" ]] && sed "s|\$HOME|$HOME|g" "$src" > "$ARDIR/$f"
done

for d in templates route_templates routestates plugin_metadata export; do
    src="$REPO_DIR/.config/ardour9/$d"
    [[ -d "$src" ]] && cp -a "$src" "$ARDIR/"
done
