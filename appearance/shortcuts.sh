#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

for file in kcminputrc kglobalshortcutsrc khotkeysrc; do
    [[ -f "$REPO_DIR/.config/$file" ]] &&
        cp -f "$REPO_DIR/.config/$file" "$HOME/.config/"
done

kquitapp6 kglobalaccel 2>/dev/null \
|| kquitapp5 kglobalaccel 2>/dev/null \
|| true

kglobalaccel6 >/dev/null 2>&1 \
|| kglobalaccel5 >/dev/null 2>&1 \
|| true &
