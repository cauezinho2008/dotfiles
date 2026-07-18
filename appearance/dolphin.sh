#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOME="${HOME:-/home/$USER}"

# ── dolphinrc ──────────────────────────────────────────────

[[ -f "$REPO_DIR/.config/dolphinrc" ]] &&
    cp -a "$REPO_DIR/.config/dolphinrc" "$HOME/.config/"

# ── dolphin data dir ───────────────────────────────────────

[[ -d "$REPO_DIR/.local/share/dolphin" ]] &&
    cp -a "$REPO_DIR/.local/share/dolphin" "$HOME/.local/share/"

# ── servicemenus ───────────────────────────────────────────

[[ -d "$REPO_DIR/.local/share/kio/servicemenus" ]] &&
    cp -a "$REPO_DIR/.local/share/kio/servicemenus" "$HOME/.local/share/kio/"

# ── kxmlgui (toolbar) ──────────────────────────────────────

[[ -d "$REPO_DIR/.local/share/kxmlgui5/dolphin" ]] &&
    cp -a "$REPO_DIR/.local/share/kxmlgui5/dolphin" "$HOME/.local/share/kxmlgui5/"

# ── dolphinstaterc ─────────────────────────────────────────

[[ -f "$REPO_DIR/.local/state/dolphinstaterc" ]] &&
    cp -a "$REPO_DIR/.local/state/dolphinstaterc" "$HOME/.local/state/"

# ── Places panel ──────────────────────────────────────────

PLACES_FILE="$HOME/.local/share/user-places.xbel"
mkdir -p "$(dirname "$PLACES_FILE")"

cat > "$PLACES_FILE" << XEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xbel>
<xbel xmlns:bookmark="http://www.freedesktop.org/standards/desktop-bookmarks" xmlns:kdepriv="http://www.kde.org/kdepriv" xmlns:mime="http://www.freedesktop.org/standards/shared-mime-info">
 <info>
  <metadata owner="http://www.kde.org">
   <kde_places_version>4</kde_places_version>
   <GroupState-Places-IsHidden>false</GroupState-Places-IsHidden>
   <GroupState-Remote-IsHidden>true</GroupState-Remote-IsHidden>
   <GroupState-Devices-IsHidden>false</GroupState-Devices-IsHidden>
   <GroupState-RemovableDevices-IsHidden>false</GroupState-RemovableDevices-IsHidden>
   <GroupState-Tags-IsHidden>false</GroupState-Tags-IsHidden>
   <withRecentlyUsed>false</withRecentlyUsed>
   <GroupState-RecentlySaved-IsHidden>true</GroupState-RecentlySaved-IsHidden>
   <withBaloo>true</withBaloo>
   <GroupState-SearchFor-IsHidden>false</GroupState-SearchFor-IsHidden>
  </metadata>
 </info>
 <bookmark href="trash:/">
  <title>Trash</title>
  <info>
   <metadata owner="http://freedesktop.org">
    <bookmark:icon name="user-trash"/>
   </metadata>
   <metadata owner="http://www.kde.org">
    <ID>1774040962/5</ID>
    <isSystemItem>true</isSystemItem>
   </metadata>
  </info>
 </bookmark>
 <bookmark href="file://$HOME">
  <title>Home</title>
  <info>
   <metadata owner="http://freedesktop.org">
    <bookmark:icon name="user-home"/>
   </metadata>
   <metadata owner="http://www.kde.org">
    <ID>1774040962/0</ID>
    <isSystemItem>true</isSystemItem>
   </metadata>
  </info>
 </bookmark>
 <bookmark href="file://$HOME/Desktop">
  <title>Desktop</title>
  <info>
   <metadata owner="http://freedesktop.org">
    <bookmark:icon name="user-desktop"/>
   </metadata>
   <metadata owner="http://www.kde.org">
    <ID>1774040962/1</ID>
    <isSystemItem>true</isSystemItem>
   </metadata>
  </info>
 </bookmark>
 <bookmark href="file://$HOME/Documents">
  <title>Documents</title>
  <info>
   <metadata owner="http://freedesktop.org">
    <bookmark:icon name="folder-documents"/>
   </metadata>
   <metadata owner="http://www.kde.org">
    <ID>1774040962/2</ID>
    <isSystemItem>true</isSystemItem>
   </metadata>
  </info>
 </bookmark>
 <bookmark href="file://$HOME/Downloads">
  <title>Downloads</title>
  <info>
   <metadata owner="http://freedesktop.org">
    <bookmark:icon name="folder-downloads"/>
   </metadata>
   <metadata owner="http://www.kde.org">
    <ID>1774040962/3</ID>
    <isSystemItem>true</isSystemItem>
   </metadata>
  </info>
 </bookmark>
 <bookmark href="file://$HOME/Music">
  <title>Music</title>
  <info>
   <metadata owner="http://freedesktop.org">
    <bookmark:icon name="folder-music"/>
   </metadata>
   <metadata owner="http://www.kde.org">
    <ID>1774040962/6</ID>
    <isSystemItem>true</isSystemItem>
   </metadata>
  </info>
 </bookmark>
 <bookmark href="file://$HOME/Pictures">
  <title>Pictures</title>
  <info>
   <metadata owner="http://freedesktop.org">
    <bookmark:icon name="folder-pictures"/>
   </metadata>
   <metadata owner="http://www.kde.org">
    <ID>1774040962/7</ID>
    <isSystemItem>true</isSystemItem>
   </metadata>
  </info>
 </bookmark>
 <bookmark href="file://$HOME/Videos">
  <title>Videos</title>
  <info>
   <metadata owner="http://freedesktop.org">
    <bookmark:icon name="folder-videos"/>
   </metadata>
   <metadata owner="http://www.kde.org">
    <ID>1774040962/8</ID>
    <isSystemItem>true</isSystemItem>
   </metadata>
  </info>
 </bookmark>
 <separator>
  <info>
   <metadata owner="http://www.kde.org">
    <isSystemItem>true</isSystemItem>
   </metadata>
  </info>
 </separator>
</xbel>
XEOF

# Hide Recent, Remote (Network) via kdeglobals
kwriteconfig6 --file kdeglobals --group "KFileDialog Settings" --key ShowRecentFiles false
kwriteconfig6 --file kdeglobals --group "KFileDialog Settings" --key ShowRemote false
kwriteconfig6 --file kdeglobals --group "KFileDialog Settings" --key ShowSpeedbar true

# ── Clear toolbar cache & restart ──────────────────────────

rm -f "$HOME/.cache/kxmlgui5/dolphin"* "$HOME/.cache/kxmlgui6/dolphin"*

pkill dolphin 2>/dev/null || true