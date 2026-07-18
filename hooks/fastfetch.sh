source /etc/os-release 2>/dev/null
DISTRO_ID="${ID:-linux}"
DISTRO_LOGO_DIR="$HOME/.config/fastfetch"
LOGO_FILE="$DISTRO_LOGO_DIR/logo"

mkdir -p "$DISTRO_LOGO_DIR"

LOGO_URL="https://raw.githubusercontent.com/everestlinux/DistroLogos/main/logos/${DISTRO_ID}.svg"

if command -v curl &>/dev/null; then
    curl -sL --connect-timeout 5 "$LOGO_URL" -o "$LOGO_FILE" 2>/dev/null || true
fi

if [[ ! -f "$LOGO_FILE" ]]; then
    for icon in "/usr/share/icons/hicolor/128x128/apps/${DISTRO_ID}.png" \
                "/usr/share/icons/hicolor/scalable/apps/${DISTRO_ID}.svg" \
                "/usr/share/icons/hicolor/symbolic/apps/${DISTRO_ID}-symbolic.svg"; do
        if [[ -f "$icon" ]]; then
            cp "$icon" "$LOGO_FILE"
            break
        fi
    done
fi

sed "s|/home/[^/]*/.config/fastfetch/[^\"']*|$LOGO_FILE|g" -i "$DISTRO_LOGO_DIR/config.jsonc" 2>/dev/null || true