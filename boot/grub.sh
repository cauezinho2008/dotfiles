#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# CachyOS boot optimizer — GRUB silent boot
#
# Makes normal boot silent:
#   - adds quiet/loglevel/splash options to the kernel cmdline
#   - suppresses "Loading Linux ..." / "Loading initial ramdisk ..."
#     messages in /etc/grub.d/10_linux
#   - neutralizes executable backup GRUB generators
#   - regenerates /boot/grub/grub.cfg (never edits it directly)
#
# Usage: grub.sh [--dry-run] [--restore]
# ==========================================================

BACKUP_ROOT="/var/backups/cachyos-boot-optimizer"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

GRUB_DEFAULT="/etc/default/grub"
GRUB_LINUX="/etc/grub.d/10_linux"
GRUB_CFG="/boot/grub/grub.cfg"

SILENT_OPTS=(quiet splash loglevel=0 systemd.show_status=false rd.udev.log_level=0 vt.global_cursor_default=0)
SILENT_MARKER="# [cachyos-silent-boot] loading messages suppressed"

DRY_RUN=0
RESTORE=0
CHANGED=0

# ---- output helpers -------------------------------------------------

if [[ -t 1 ]]; then
    c_green=$'\033[32m'; c_yellow=$'\033[33m'; c_red=$'\033[31m'; c_cyan=$'\033[36m'; c_reset=$'\033[0m'
else
    c_green=; c_yellow=; c_red=; c_cyan=; c_reset=
fi

info() { echo "${c_cyan}[grub]${c_reset} $*"; }
ok()   { echo "${c_green}  ✔ $*${c_reset}"; }
warn() { echo "${c_yellow}  ! $*${c_reset}"; }
die()  { echo "${c_red}  ✘ $*${c_reset}"; exit 1; }

[[ "$EUID" -eq 0 ]] || die "Run as root."

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTION]

CachyOS GRUB silent boot optimizer.

  --dry-run   print what would be changed without modifying anything
  --restore   restore the latest backup
  -h, --help  show this help
EOF
}

# ---- backup / restore ----------------------------------------------

backup_file() {
    local f="$1"
    [[ -f "$f" ]] || return 0
    mkdir -p "$BACKUP_DIR$(dirname "$f")"
    cp -a "$f" "$BACKUP_DIR$f"
    info "backed up: $f"
}

restore_latest() {
    local latest
    latest="$(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -n1)"
    [[ -n "$latest" ]] || die "No backups found under $BACKUP_ROOT"
    info "restoring from: $latest"
    while IFS= read -r f; do
        local rel="${f#"$latest"/}"
        mkdir -p "/$(dirname "$rel")"
        cp -a "$f" "/$rel"
        ok "restored: /$rel"
    done < <(find "$latest" -type f)
    echo
    info "regenerating GRUB config after restore..."
    grub-mkconfig -o "$GRUB_CFG"
}

# ---- 1. kernel cmdline ---------------------------------------------

ensure_cmdline() {
    local key="$1"
    shift
    local line cur new_cur token

    line="$(grep -E "^${key}=" "$GRUB_DEFAULT" 2>/dev/null | tail -n1)"
    if [[ -z "$line" ]]; then
        warn "${key} not found in $GRUB_DEFAULT — skipping"
        return 0
    fi

    cur="$(sed -E "s/^${key}=\"?//; s/\"?\$//" <<<"$line")"
    new_cur="$cur"
    for token in "$@"; do
        [[ " $new_cur " == *" $token "* ]] || new_cur="$new_cur $token"
    done
    new_cur="$(echo "$new_cur" | xargs)"

    if [[ "$cur" == "$new_cur" ]]; then
        ok "${key} already has all silent options"
    else
        if [[ $DRY_RUN -eq 1 ]]; then
            info "would set ${key}=\"${new_cur}\""
        else
            backup_file "$GRUB_DEFAULT"
            sed -i "s|^${key}=.*|${key}=\"${new_cur}\"|" "$GRUB_DEFAULT"
            ok "updated ${key}"
        fi
        CHANGED=1
    fi
}

# ---- 2. suppress loading messages in 10_linux ----------------------

silence_10_linux() {
    if grep -qE '^[[:space:]]*echo "\$message"' "$GRUB_LINUX" 2>/dev/null; then
        if grep -q 'cachyos-silent-boot' "$GRUB_LINUX" 2>/dev/null; then
            ok "loading messages already suppressed in 10_linux"
        else
            if [[ $DRY_RUN -eq 1 ]]; then
                info "would comment out 'echo \$message' lines in $GRUB_LINUX"
            else
                backup_file "$GRUB_LINUX"
                sed -i "s|^\([[:space:]]*\)echo \"\$message\"|$SILENT_MARKER\\n# \\1echo \"\$message\"|" "$GRUB_LINUX"
                ok "suppressed loading messages in 10_linux"
            fi
            CHANGED=1
        fi
    else
        ok "no loading-message echo lines found (already silent)"
    fi
}

# ---- 3. neutralize executable backup generators --------------------

handle_backup_generators() {
    local bak found=0
    while IFS= read -r bak; do
        [[ -e "$bak" ]] || continue
        found=1
        if [[ -x "$bak" ]]; then
            warn "executable backup generator found: $bak"
            if [[ $DRY_RUN -eq 1 ]]; then
                info "would make non-executable: $bak"
            else
                backup_file "$bak"
                chmod -x "$bak"
                ok "made non-executable: $bak"
            fi
            CHANGED=1
        else
            ok "backup generator not executable: $bak"
        fi
    done < <(find /etc/grub.d -maxdepth 1 \( -name '*.bak' -o -name '*~' \) 2>/dev/null | sort)
    [[ "$found" -eq 0 ]] && ok "no backup generators found"
}

# ---- 4. regenerate GRUB --------------------------------------------

regen_grub() {
    if [[ $DRY_RUN -eq 1 ]]; then
        info "would run: grub-mkconfig -o $GRUB_CFG"
    else
        grub-mkconfig -o "$GRUB_CFG"
        ok "GRUB config regenerated"
    fi
}

# ---- 5. verification / report --------------------------------------

verify_entries() {
    local n
    n="$(grep -c '^menuentry ' "$GRUB_CFG" 2>/dev/null || true)"
    if [[ "$n" -eq 0 ]]; then
        warn "no menuentry lines found in $GRUB_CFG"
    else
        ok "$n menu entries generated"
    fi
}

report() {
    echo
    echo "=== GRUB report ==="
    echo "  cmdline: $(grep -E '^GRUB_CMDLINE_LINUX_DEFAULT=' "$GRUB_DEFAULT" 2>/dev/null | tail -n1)"
    if grep -q 'cachyos-silent-boot' "$GRUB_LINUX" 2>/dev/null; then
        echo "  10_linux: loading messages suppressed"
    else
        echo "  10_linux: loading messages present (check)"
    fi
    local baks
    baks="$(find /etc/grub.d -maxdepth 1 \( -name '*.bak' -o -name '*~' \) -perm -u+x 2>/dev/null | sort)"
    if [[ -n "$baks" ]]; then
        echo "  executable .bak generators: FOUND"
        echo "$baks" | sed 's/^/    /'
    else
        echo "  executable .bak generators: none"
    fi

    cat <<'EOF'

  Manual BIOS settings (cannot be automated from Linux):
   • BIOS Fast Boot:            ENABLED
   • BIOS setup / F2 timeout:   0
   • Boot-device / F12 timeout: 0
   • Unused SATA/data ports:    DISABLED
   • Network Stack:             DISABLED
   • IPv4/IPv6 PXE & HTTP Boot: disabled
   • USB boot:                  enabled and FIRST
   • CachyOS / NVMe boot entry: available
EOF
}

# ---- main ----------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --restore) RESTORE=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1"; usage; exit 1 ;;
    esac
    shift
done

info "GRUB silent boot optimizer"

if [[ "$RESTORE" -eq 1 ]]; then
    restore_latest
    report
    exit 0
fi

ensure_cmdline "GRUB_CMDLINE_LINUX_DEFAULT" "${SILENT_OPTS[@]}"
silence_10_linux
handle_backup_generators

if [[ $CHANGED -eq 1 ]] || [[ $DRY_RUN -eq 1 ]]; then
    regen_grub
    verify_entries
else
    ok "no changes needed — GRUB already silent"
fi

report
exit 0