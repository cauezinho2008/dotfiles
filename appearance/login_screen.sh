#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

PLASMALOGIN_CONF="/etc/plasmalogin.conf"
WALLPAPER_SRC="$(find "$REPO_DIR/wallpapers" -maxdepth 1 -type f | head -n1)"

if [[ -z "$WALLPAPER_SRC" ]]; then
    echo "No wallpaper found in $REPO_DIR/wallpapers/"
    exit 1
fi

WALLPAPER_DIR="/var/lib/plasmalogin/wallpapers"
WALLPAPER_NAME="$(basename "$WALLPAPER_SRC")"

FONT_NAME="ProFont IIx Nerd Font Mono"
FONT_SIZE=10
FONT_VALUES="$FONT_NAME,$FONT_SIZE,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,,0,0"

TMPFILE="$(mktemp)"
cat > "$TMPFILE" << EOF
[Autologin]
Session=plasma

[Greeter]
Font=$FONT_VALUES

[Greeter][Wallpaper][org.kde.image][General]
Blur=true
FillMode=0
Image=file://$WALLPAPER_DIR/$WALLPAPER_NAME
EOF

run_priv() {
    local cmd="$1"

    if command -v pkexec &>/dev/null; then
        pkexec sh -c "$cmd" && return 0
    fi

    if sudo -n true 2>/dev/null; then
        sudo sh -c "$cmd" && return 0
    fi

    for i in $(seq 30); do
        if yes | sudo -S sh -c "$cmd" 2>/dev/null; then
            return 0
        fi
        sleep 2
    done

    echo "Failed to get administrator privileges for login screen config."
    echo "Try running: sudo $0"
    return 1
}

CMD="mkdir -p $WALLPAPER_DIR && cp -f $WALLPAPER_SRC $WALLPAPER_DIR/ && cp -f $TMPFILE $PLASMALOGIN_CONF"
run_priv "$CMD"

rm -f "$TMPFILE"

echo "Wallpaper copied to $WALLPAPER_DIR/$WALLPAPER_NAME"

echo "Plasma login manager settings applied"
