#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$HOME/.config"

cp -f "$REPO_DIR/.config/kglobalshortcutsrc" \
      "$HOME/.config/"

# Reload the global shortcut daemon
#if qdbus org.kde.kglobalaccel /component/kwin >/dev/null #2>&1; then
#    qdbus org.kde.KGlobalAccel /kglobalaccel #org.kde.KGlobalAccel.reloadConfig >/dev/null 2>&1 || true
#fi

# Fallback: restart the daemon
#kquitapp6 kglobalacceld >/dev/null 2>&1 || \
#kquitapp5 kglobalacceld >/dev/null 2>&1 || true

#sleep 1

#kglobalacceld >/dev/null 2>&1 &
