#!/usr/bin/env bash

# ==========================================================
# Cauê's Dotfiles Installer - Copy Dotfiles
# ==========================================================

set -euo pipefail

# ==========================================================
# Gum theme
# ==========================================================

export GUM_CHOOSE_CURSOR_FOREGROUND="#6A9EFF"
export GUM_CHOOSE_SELECTED_FOREGROUND="#6A9EFF"

export GUM_CONFIRM_PROMPT_FOREGROUND="#6A9EFF"
export GUM_CONFIRM_SELECTED_FOREGROUND="#FFFFFF"
export GUM_CONFIRM_SELECTED_BACKGROUND="#217CB5"

export GUM_INPUT_CURSOR_FOREGROUND="#6A9EFF"
export GUM_SPIN_SPINNER_FOREGROUND="#6A9EFF"

# ==========================================================
# Paths
# ==========================================================

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

CONFIG_DIR="$REPO_DIR/.config"
LOCAL_SHARE_DIR="$REPO_DIR/.local/share"
POSH_DIR="$REPO_DIR/.poshthemes"

PREVIEW_DIR="$REPO_DIR/preview"
EXCLUDED_FILE="$REPO_DIR/excluded.txt"

BACKUP_ROOT="$HOME/.dotfiles-backup"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

# ==========================================================
# Dependency check
# ==========================================================

source /etc/os-release

case "$ID" in
    arch|cachyos|endeavouros|manjaro)
        INSTALL_CMD="sudo pacman -S --needed"
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
        echo "Unsupported distribution."
        exit 1
        ;;
esac

INSTALLED_NOW=()
MISSING=()

for dep in chafa fzf gum; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        MISSING+=("$dep")
    fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo
    echo "Required dependencies are missing:"
    printf "  - %s\n" "${MISSING[@]}"
    echo

    read -rp "Install them now? [Y/n]: " ans

    if [[ "${ans,,}" == "n" ]]; then
        exit 1
    fi

    for dep in "${MISSING[@]}"; do
        eval "$INSTALL_CMD $dep"
        INSTALLED_NOW+=("$dep")
    done
fi

# ==========================================================
# Header
# ==========================================================

clear

gum style \
    --foreground 39 \
    --bold \
    --align center \
"Copy Dotfiles"

echo

gum style \
    --foreground 33 \
    --align center \
"Repository: $(basename "$REPO_DIR")"

echo

gum style \
    --foreground 33 \
    --align center \
"Tab: Toggle   Ctrl+A: All   Ctrl+D: None   Enter: Copy"

echo

# ==========================================================
# Load exclusions
# ==========================================================

EXCLUDED=()

if [[ -f "$EXCLUDED_FILE" ]]; then
    mapfile -t EXCLUDED < <(
        grep -v '^#' "$EXCLUDED_FILE" |
        grep -v '^[[:space:]]*$'
    )
fi

is_excluded() {
    local p="$1"

    for ex in "${EXCLUDED[@]}"; do
        [[ "$p" == "$ex" ]] && return 0
    done

    return 1
}

# ==========================================================
# Build item database
# ==========================================================

DISPLAY_LIST=()
REAL_PATHS=()

# .config
if [[ -d "$CONFIG_DIR" ]]; then
    while IFS= read -r item; do
        rel=".config/$(basename "$item")"

        is_excluded "$rel" && continue

        DISPLAY_LIST+=("$(basename "$item")")
        REAL_PATHS+=("$rel")

    done < <(find "$CONFIG_DIR" -mindepth 1 -maxdepth 1 | sort)
fi

# .local/share
if [[ -d "$LOCAL_SHARE_DIR" ]]; then
    while IFS= read -r item; do
        rel=".local/share/$(basename "$item")"

        is_excluded "$rel" && continue

        DISPLAY_LIST+=("$(basename "$item")")
        REAL_PATHS+=("$rel")

    done < <(find "$LOCAL_SHARE_DIR" -mindepth 1 -maxdepth 1 | sort)
fi

# .poshthemes
if [[ -d "$POSH_DIR" ]]; then
    is_excluded ".poshthemes" || {
        DISPLAY_LIST+=(".poshthemes")
        REAL_PATHS+=(".poshthemes")
    }
fi

# ==========================================================
# fzf selection
# ==========================================================

SELECTED=$(
    printf "%s\n" "${DISPLAY_LIST[@]}" |
    fzf \
        --multi \
        --layout=reverse \
        --border=rounded \
        --height=75% \
        --prompt="search: " \
        --pointer="▶ " \
        --marker="*" \
        --bind 'tab:toggle' \
        --bind 'ctrl-a:select-all' \
        --bind 'ctrl-d:deselect-all' \
        --bind 'esc:abort' \
        --color=bg:-1,bg+:#112240,fg:#d0d0d0,fg+:#ffffff \
        --color=border:#4A6FA5,header:#6A9EFF,info:#6A9EFF \
        --color=pointer:#6A9EFF,marker:#6A9EFF,prompt:#6A9EFF \
        --color=spinner:#6A9EFF,hl:#6A9EFF,hl+:#8BB8FF \
        --preview "
bash -c '
item=\"\$1\"
name=\$(basename \"\$item\")
\"$REPO_DIR/preview_image.sh\" \"\$name\"
' _ {}
"\
        --preview-window=right:55%:wrap
) || exit 0

# ==========================================================
# Resolve selected paths
# ==========================================================

TO_COPY=()

while IFS= read -r selected; do
    [[ -z "$selected" ]] && continue

    for i in "${!DISPLAY_LIST[@]}"; do
        if [[ "${DISPLAY_LIST[$i]}" == "$selected" ]]; then
            TO_COPY+=("${REAL_PATHS[$i]}")
            break
        fi
    done

done <<< "$SELECTED"

if [[ ${#TO_COPY[@]} -eq 0 ]]; then
    exit 0
fi

# ==========================================================
# Backup prompt
# ==========================================================

echo

BACKUP=false

if gum confirm "Create a backup before copying?"; then
    BACKUP=true
    BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

    mkdir -p \
        "$BACKUP_DIR/.config" \
        "$BACKUP_DIR/.local/share"

    for item in "${TO_COPY[@]}"; do
        case "$item" in
            .config/*)
                name="$(basename "$item")"
                [[ -e "$HOME/.config/$name" ]] &&
                    cp -a "$HOME/.config/$name" "$BACKUP_DIR/.config/"
                ;;
            .local/share/*)
                name="$(basename "$item")"
                [[ -e "$HOME/.local/share/$name" ]] &&
                    cp -a "$HOME/.local/share/$name" "$BACKUP_DIR/.local/share/"
                ;;
            .poshthemes)
                [[ -e "$HOME/.poshthemes" ]] &&
                    cp -a "$HOME/.poshthemes" "$BACKUP_DIR/"
                ;;
        esac
    done
fi

# ==========================================================
# Confirmation
# ==========================================================

clear

gum style \
    --foreground 39 \
    --bold \
    --align center \
"Copy Dotfiles"

echo

gum style \
    --foreground 33 \
    --align center \
"The following items will be copied"

echo

for item in "${TO_COPY[@]}"; do
    printf "  • %s\n" "$item"
done

echo

gum confirm "Continue?" || exit 0

# ==========================================================
# Copy
# ==========================================================

mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/share"

gum spin --spinner dot --title "Copying selected dotfiles..." -- sleep 0.1

for item in "${TO_COPY[@]}"; do
    case "$item" in
        .config/*)
            cp -a "$REPO_DIR/$item" "$HOME/.config/"
            ;;
        .local/share/*)
            cp -a "$REPO_DIR/$item" "$HOME/.local/share/"
            ;;
        .poshthemes)
            cp -a "$REPO_DIR/.poshthemes" "$HOME/"
            ;;
    esac
done

echo
gum style \
    --foreground 39 \
    --align center \
"Copy complete."

# ==========================================================
# Cleanup
# ==========================================================

if [[ ${#INSTALLED_NOW[@]} -gt 0 ]]; then
    echo

    if gum confirm "Remove temporary dependencies?"; then
        eval "$REMOVE_CMD ${INSTALLED_NOW[*]}"
    fi
fi

exit 0
