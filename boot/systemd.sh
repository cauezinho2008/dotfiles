#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# CachyOS boot optimizer — systemd services
#
# Only touches the services listed below. Everything else
# (NetworkManager, dbus, resolved, udevd, logind, polkit,
# journald, oomd, ananicy-cpp, bpftune, upower, udisks2,
# snapper, etc.) is left alone.
#
#   NetworkManager-wait-online.service  -> disabled (biggest boot delay)
#   avahi-daemon.service                -> disabled (unused)
#   avahi-daemon.socket                 -> disabled (unused)
#   bluetooth.service                   -> enabled + started (keep BT)
#
# Usage: systemd.sh [--dry-run] [--restore]
# ==========================================================

BACKUP_ROOT="/var/backups/cachyos-boot-optimizer"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

MANAGE_UNITS=(
    NetworkManager-wait-online.service
    avahi-daemon.service
    avahi-daemon.socket
    bluetooth.service
)

DRY_RUN=0
RESTORE=0
CHANGED=0

# ---- output helpers -------------------------------------------------

if [[ -t 1 ]]; then
    c_green=$'\033[32m'; c_yellow=$'\033[33m'; c_red=$'\033[31m'; c_cyan=$'\033[36m'; c_reset=$'\033[0m'
else
    c_green=; c_yellow=; c_red=; c_cyan=; c_reset=
fi

info() { echo "${c_cyan}[systemd]${c_reset} $*"; }
ok()   { echo "${c_green}  ✔ $*${c_reset}"; }
warn() { echo "${c_yellow}  ! $*${c_reset}"; }
die()  { echo "${c_red}  ✘ $*${c_reset}"; exit 1; }

[[ "$EUID" -eq 0 ]] || die "Run as root."

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTION]

CachyOS systemd boot service optimizer.

  --dry-run   print what would be changed without modifying anything
  --restore   restore service states from the latest backup
  -h, --help  show this help
EOF
}

# ---- backup / restore ----------------------------------------------

backup_states() {
    mkdir -p "$BACKUP_DIR"
    for u in "${MANAGE_UNITS[@]}"; do
        echo "$u $(systemctl is-enabled "$u" 2>/dev/null || echo unknown)"
    done > "$BACKUP_DIR/service-states.txt"
    info "recorded service states in $BACKUP_DIR/service-states.txt"
}

restore_latest() {
    local latest
    latest="$(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -n1)"
    [[ -n "$latest" ]] || die "No backups found under $BACKUP_ROOT"
    local states="$latest/service-states.txt"
    if [[ ! -f "$states" ]]; then
        info "no service states recorded in $latest — nothing to restore"
        exit 0
    fi
    info "restoring service states from: $states"
    local unit state
    while read -r unit state; do
        case "$state" in
            enabled)
                systemctl enable "$unit" 2>/dev/null || true
                systemctl start "$unit" 2>/dev/null || true
                ok "enabled + started $unit"
                ;;
            disabled)
                systemctl disable "$unit" 2>/dev/null || true
                systemctl stop "$unit" 2>/dev/null || true
                ok "disabled + stopped $unit"
                ;;
            *)
                info "skipping $unit (state: ${state:-unknown})"
                ;;
        esac
    done < "$states"
}

# ---- unit helpers ---------------------------------------------------

ensure_disabled() {
    local unit="$1"
    local state
    state="$(systemctl is-enabled "$unit" 2>/dev/null || true)"
    if [[ "$state" == "disabled" ]]; then
        ok "$unit already disabled"
    elif [[ "$state" == "masked" ]]; then
        warn "$unit is masked — leaving as is"
    else
        if [[ $DRY_RUN -eq 1 ]]; then
            info "would disable + stop $unit"
        else
            systemctl disable "$unit" 2>/dev/null || true
            systemctl stop "$unit" 2>/dev/null || true
            ok "disabled + stopped $unit"
        fi
        CHANGED=1
    fi
}

ensure_enabled() {
    local unit="$1"
    local state
    state="$(systemctl is-enabled "$unit" 2>/dev/null || true)"
    if [[ "$state" == "enabled" ]]; then
        ok "$unit already enabled"
    else
        if [[ $DRY_RUN -eq 1 ]]; then
            info "would enable + start $unit"
        else
            systemctl enable "$unit" 2>/dev/null || true
            systemctl start "$unit" 2>/dev/null || true
            ok "enabled + started $unit"
        fi
        CHANGED=1
    fi
}

# ---- report ---------------------------------------------------------

report() {
    echo
    echo "=== systemd report ==="
    for u in "${MANAGE_UNITS[@]}"; do
        printf "  %-42s %s\n" "$u" "$(systemctl is-enabled "$u" 2>/dev/null || echo unknown)"
    done
    echo
    info "boot analysis:"
    systemd-analyze
    echo
    systemd-analyze critical-chain
    echo
}

# ---- main -----------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --restore) RESTORE=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1"; usage; exit 1 ;;
    esac
    shift
done

info "systemd boot service optimizer"

if [[ "$RESTORE" -eq 1 ]]; then
    restore_latest
    report
    exit 0
fi

backup_states

ensure_disabled "NetworkManager-wait-online.service"
ensure_disabled "avahi-daemon.service"
ensure_disabled "avahi-daemon.socket"
ensure_enabled "bluetooth.service"

if [[ $DRY_RUN -eq 1 ]]; then
    info "dry run — nothing was modified"
fi

report
exit 0