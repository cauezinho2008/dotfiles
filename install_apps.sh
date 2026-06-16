#!/usr/bin/env bash

# ==========================================================
# Gum colors
# ==========================================================

# ==========================================================
# Gum theme
# ==========================================================

export GUM_CHOOSE_CURSOR_FOREGROUND="#6A9EFF"
export GUM_CHOOSE_SELECTED_FOREGROUND="#6A9EFF"
export GUM_CHOOSE_HEADER_FOREGROUND="#4A6FA5"

export GUM_CONFIRM_PROMPT_FOREGROUND="#6A9EFF"
export GUM_CONFIRM_SELECTED_FOREGROUND="#6A9EFF"

export GUM_INPUT_CURSOR_FOREGROUND="#6A9EFF"
export GUM_SPIN_SPINNER_FOREGROUND="#6A9EFF"

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
PACKAGES_FILE="$REPO_DIR/packages.txt"

# ==========================================================
# Detect distro
# ==========================================================

source /etc/os-release

case "$ID" in
    arch|cachyos|endeavouros|manjaro)
        PKG_INSTALL="sudo pacman -S --needed"
        PKG_CHECK="pacman -Q"
        PKG_INFO="pacman -Si"
        PKG_NAME="pacman"
        ;;
    ubuntu|debian|linuxmint|pop)
        PKG_INSTALL="sudo apt install -y"
        PKG_CHECK="dpkg -s"
        PKG_INFO="apt show"
        PKG_NAME="apt"
        ;;
    fedora)
        PKG_INSTALL="sudo dnf install -y"
        PKG_CHECK="rpm -q"
        PKG_INFO="dnf info"
        PKG_NAME="dnf"
        ;;
    *)
        echo "Unsupported distro."
        exit 1
        ;;
esac

# ==========================================================
# Header
# ==========================================================

clear

gum style \
    --foreground 39 \
    --bold \
    --align center \
"Applications"

echo

gum style \
    --foreground 33 \
    --align center \
"Package manager: $PKG_NAME"

echo
gum style \
    --foreground 33 \
    --align center \
"Tab: Toggle   Ctrl+A: All   Ctrl+D: None   Enter: Install"

echo

# ==========================================================
# Read packages
# ==========================================================

if [[ ! -f "$PACKAGES_FILE" ]]; then
    gum style --foreground 196 "packages.txt not found."
    exit 1
fi

mapfile -t PACKAGES < <(
    grep -v '^#' "$PACKAGES_FILE" |
    grep -v '^[[:space:]]*$'
)

DISPLAY_LIST=()

for pkg in "${PACKAGES[@]}"; do
    if $PKG_CHECK "$pkg" >/dev/null 2>&1; then
        # Installed -> gray
        DISPLAY_LIST+=($'\033[2m✓ '"$pkg"$'\033[0m')
    else
        DISPLAY_LIST+=("○ $pkg")
    fi
done

# ==========================================================
# Selection UI
# ==========================================================

SELECTED=$(
    printf "%s\n" "${DISPLAY_LIST[@]}" |
    fzf \
        --color=bg:-1,bg+:#112240,fg:#d0d0d0,fg+:#ffffff \
--color=border:#4A6FA5,header:#6A9EFF,info:#6A9EFF \
--color=pointer:#6A9EFF,marker:#6A9EFF,prompt:#6A9EFF \
--color=spinner:#6A9EFF,hl:#6A9EFF,hl+:#8BB8FF \
--multi \
        --ansi \
        --layout=reverse \
        --border=rounded \
        --height=75% \
        --prompt="search:" \
        --pointer="▶" \
        --marker="✓" \
        --header=$'' \
        --bind 'ctrl-a:select-all' \
        --bind 'ctrl-d:deselect-all' \
        --bind 'esc:abort' \
        --preview "
bash -c '
pkg=\"\$1\"
pkg=\${pkg#??}
pkg=\$(printf \"%s\" \"\$pkg\" | sed \"s/\x1b\[[0-9;]*m//g\")

if $PKG_CHECK \"\$pkg\" >/dev/null 2>&1; then
    echo \"✓ Already installed\"
    echo
    $PKG_INFO \"\$pkg\" 2>/dev/null | head -15
else
    $PKG_INFO \"\$pkg\" 2>/dev/null | head -20
fi
' _ {}
"\
        --preview-window=right:55%
) || exit 0

# ==========================================================
# Parse selection
# ==========================================================

TO_INSTALL=()

while IFS= read -r line; do
    [[ -z "$line" ]] && continue

    pkg=$(echo "$line" | sed 's/^[✓○] //' | sed 's/\x1b\[[0-9;]*m//g')

    if ! $PKG_CHECK "$pkg" >/dev/null 2>&1; then
        TO_INSTALL+=("$pkg")
    fi
done <<< "$SELECTED"

# Nothing selected
if [[ ${#TO_INSTALL[@]} -eq 0 ]]; then
    gum style \
        --foreground 214 \
        --align center \
"No installable applications selected."

    echo
    read -rp "Press Enter to return..."
    exit 0
fi

# ==========================================================
# Confirmation
# ==========================================================

clear

gum style \
    --foreground 39 \
    --bold \
    --align center \
"Applications"

echo

gum style \
    --foreground 33 \
    --align center \
"The following packages will be installed"

echo
printf "  • %s\n" "${TO_INSTALL[@]}"
echo

if gum confirm "Continue?"; then
    $PKG_INSTALL "${TO_INSTALL[@]}"

    echo
    gum style \
        --foreground 39 \
        --align center \
"Installation complete."

    #echo
    #read -rp "Press Enter to return..."
fi
