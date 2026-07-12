#!/usr/bin/env bash

set -euo pipefail

# ==========================================================
# Cauê's Dotfiles Installer
# ==========================================================

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

CHAOTIC_SCRIPT="$REPO_DIR/setup_chaotic.sh"
APP_SCRIPT="$REPO_DIR/install_apps.sh"
COPY_SCRIPT="$REPO_DIR/copy_dotfiles.sh"
KDE_SCRIPT="$REPO_DIR/kde.sh"
RESTORE_SCRIPT="$REPO_DIR/restore_backup.sh"

# ==========================================================
# Detect distro
# ==========================================================

source /etc/os-release

DISTRO_ID="$ID"
DISTRO_NAME="$PRETTY_NAME"

case "$DISTRO_ID" in
    arch|cachyos|endeavouros|manjaro)
        INSTALL_CMD="sudo pacman -Sy --needed --noconfirm"
        REMOVE_CMD="sudo pacman -Rns --noconfirm"
        ;;
    ubuntu|debian|linuxmint|pop)
        INSTALL_CMD="sudo apt update && sudo apt install -y"
        REMOVE_CMD="sudo apt remove -y"
        ;;
    fedora)
        INSTALL_CMD="sudo dnf install -y"
        REMOVE_CMD="sudo dnf remove -y"
        ;;
    *)
        echo "Unsupported distribution:"
        echo "$DISTRO_NAME"
        exit 1
        ;;
esac

# ==========================================================
# Dependency check
# ==========================================================

DEPS=(gum fzf chafa)
INSTALLED_NOW=()
MISSING=()

for dep in "${DEPS[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        MISSING+=("$dep")
    fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo
    echo "Required dependencies are missing:"
    printf "  - %s\n" "${MISSING[@]}"
    echo

    read -rp "Install them now? [Y/n]: " ans < /dev/tty

    if [[ "${ans,,}" == "n" ]]; then
        echo "Cannot continue."
        exit 1
    fi

    for dep in "${MISSING[@]}"; do
        echo "Installing $dep..."
        eval "$INSTALL_CMD $dep"
        INSTALLED_NOW+=("$dep")
    done
fi

# ==========================================================
# Gum colors
# ==========================================================

#export GUM_CHOOSE_CURSOR_FOREGROUND="39"
#export GUM_CHOOSE_SELECTED_FOREGROUND="39"
#export GUM_CHOOSE_HEADER_FOREGROUND="39"
#export GUM_CONFIRM_PROMPT_FOREGROUND="39"
#export GUM_CONFIRM_SELECTED_FOREGROUND="39"
#export GUM_SPIN_SPINNER_FOREGROUND="39"
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
# ==========================================================
# UI helpers
# ==========================================================

draw_header() {
    clear

    gum style \
        --foreground 39 \
        --bold \
        --align center \
"Cauê's Dotfiles Installer"
echo

    gum style \
        --foreground 33 \
        --align center \
"$(echo "$DISTRO_NAME" | cut -d' ' -f1) detected"


}

run_script() {
    local script="$1"
    local title="$2"

    clear

    if [[ ! -f "$script" ]]; then
        gum style \
            --border normal \
            --border-foreground 196 \
            --width 52 \
            --align center \
"$title

Script not found."
        echo
        read -rp "Press Enter to return..."
        return
    fi

    bash "$script"

    #echo
    #read -rp "Press Enter to return to the menu..."
}

# ==========================================================
# Main menu
# ==========================================================

while true; do

    draw_header
    echo

   # Build menu
MENU_ITEMS=()

# Show only on Arch-based distros
case "$DISTRO_ID" in
    arch|cachyos|endeavouros|manjaro)
        MENU_ITEMS+=("Setup Chaotic-AUR")
        ;;
esac

MENU_ITEMS+=(
    "Applications"
    "Copy dotfiles"
    "KDE appearance"
    "Exit"
)

CHOICE=$(
    printf "%s\n" "${MENU_ITEMS[@]}" |
    gum choose \
        --cursor=" ▶ " \
        --cursor.foreground="39" \
        --selected.foreground="39" \
        --height=8
)

    case "$CHOICE" in

         "Setup Chaotic-AUR")
            run_script "$CHAOTIC_SCRIPT" "Chaotic-AUR Setup"
            ;;

        "Applications")
            run_script "$APP_SCRIPT" "Application installer"
            ;;

        "Copy dotfiles")
            run_script "$COPY_SCRIPT" "Copy dotfiles"
            ;;

        "KDE appearance")
            run_script "$KDE_SCRIPT" "KDE appearance"
            ;;

        "Restore backup")
            run_script "$RESTORE_SCRIPT" "Restore backup"
            ;;

        "Exit"|*)
            break
            ;;

    esac

done

# ==========================================================
# Cleanup
# ==========================================================

clear

if [[ ${#INSTALLED_NOW[@]} -gt 0 ]]; then
    echo

    if gum confirm "Remove temporary dependencies before exiting?"; then
        case "$DISTRO_ID" in
            arch|cachyos|endeavouros|manjaro)
                sudo pacman -Rns --noconfirm "${INSTALLED_NOW[@]}"
                ;;
            ubuntu|debian|linuxmint|pop)
                sudo apt remove -y "${INSTALLED_NOW[@]}"
                ;;
            fedora)
                sudo dnf remove -y "${INSTALLED_NOW[@]}"
                ;;
        esac
    fi
fi
clear
# ==========================================================
# Reboot recommendation
# ==========================================================

clear

gum style \
    --foreground 214 \
    --bold \
    --align center \
"Before you go..."

echo

gum style \
    --foreground 245 \
"Most changes are already active.

If you installed applications or applied KDE appearance,
a reboot is recommended to ensure everything is loaded correctly.

This includes things such as:

 • Fonts
 • Cursor themes
 • Global shortcuts
 • Plasma components
 • Newly installed applications and services

You can continue using your system normally,
but restarting now is recommended."

echo

CHOICE=$(
    gum choose \
        "ROBOOT NOW" \
        "Reboot later"
)

case "$CHOICE" in
    "REBOOT NOW")
        sudo reboot
        ;;
    "Reboot later"|*)
        ;;
esac

clear
exit 0
exit 0

