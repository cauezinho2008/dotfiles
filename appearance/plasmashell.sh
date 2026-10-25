#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Stop plasmashell to avoid conflicts
kquitapp6 plasmashell 2>/dev/null || true
sleep 1

# Remove existing panel containments from live config to avoid duplicates
LIVE_APPLETS="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
if [[ -f "$LIVE_APPLETS" ]]; then
    # Remove any containment with plugin=org.kde.panel (formfactor=2)
    python3 - "$LIVE_APPLETS" << 'PYEOF'
import configparser, sys
cfg = configparser.ConfigParser(strict=False)
cfg.optionxform = str
cfg.read(sys.argv[1])

# Find panel containments (formfactor=2 and plugin=org.kde.panel)
to_remove = []
for section in cfg.sections():
    if section.startswith("Containments]["):
        # Check if this is a panel containment
        if cfg.get(section, "plugin", fallback="") == "org.kde.panel":
            to_remove.append(section)

# Also remove their applets
for section in list(cfg.sections()):
    for panel in to_remove:
        if section.startswith(panel + "]["):
            cfg.remove_section(section)
            break

for panel in to_remove:
    cfg.remove_section(panel)

with open(sys.argv[1], "w") as f:
    cfg.write(f)
print(f"Removed {len(to_remove)} panel containment(s)")
PYEOF
fi

# Apply plasmashellrc and plasmarc
for file in plasmashellrc plasmarc; do
    if [[ -f "$REPO_DIR/.config/$file" ]]; then
        sed "s|\$HOME|$HOME|g" "$REPO_DIR/.config/$file" > "$HOME/.config/$file"
    fi
done

# Apply appletsrc (with panel config from repo)
APPLETS="$REPO_DIR/.config/plasma-org.kde.plasma.desktop-appletsrc"
if [[ -f "$APPLETS" ]]; then
    sed "s|\$HOME|$HOME|g" "$APPLETS" > "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
fi

# Restart plasmashell
kstart5 plasmashell 2>/dev/null || plasmashell --replace &
sleep 2

echo "Plasmashell config applied (panel replaced)"
