# Dotfiles Internal Documentation

This document explains the internal architecture of this repository.

It covers:

* how the installer works
* how configs are discovered
* how hooks are linked
* how previews work
* how appearance modules apply
* how package installation works
* how temporary sessions are managed
* how everything is modular by filename

This project is built entirely around a **matching-name modular architecture**.

That means:

```text
fish
```

can simultaneously represent:

```text
.config/fish
hooks/fish.sh
preview/fish.png
preview/fish.txt
```

All linked automatically.

---

# Table of Contents

* [Overview](#overview)
* [Project Structure](#project-structure)
* [Main Execution Flow](#main-execution-flow)
* [setup.sh](#setupsh)
* [main.sh](#mainsh)
* [setup_chaotic.sh](#setup_chaoticsh)
* [install_apps.sh](#install_appssh)
* [copy_dotfiles.sh](#copy_dotfilessh)
* [excluded.txt](#excludedtxt)
* [hooks System](#hooks-system)
* [appearance.sh](#appearancesh)
* [preview.sh](#previewsh)
* [Appearance Modules](#appearance-modules)
* [Temporary Sessions](#temporary-sessions)
* [Dependency Handling](#dependency-handling)
* [How to Extend](#how-to-extend)

---

# Overview

This installer restores my Linux environment through modular scripts.

Main features:

* app installation
* dotfiles
* KDE appearance
* power profiles
* cursor installation
* font installation
* wallpapers
* Plasma layouts
* shell themes

Everything works by scanning directories dynamically.

No hardcoded entries.

Adding files automatically expands the installer.

---

# Project Structure

```text
.
├── appearance
│   ├── colorscheme.sh
│   ├── cursor.sh
│   ├── kwin.sh
│   ├── launcher.sh
│   ├── order.txt
│   ├── plasmashell.sh
│   ├── shortcuts.sh
│   └── wallpaper.sh
├── appearance.sh
├── copy_dotfiles.sh
├── excluded.txt
├── hooks
│   ├── colorscheme.sh
│   ├── dolphin.sh
│   ├── fastfetch.sh
│   ├── fish.sh
│   ├── gtk.sh
│   ├── kitty.sh
│   └── power.sh
├── install_apps.sh
├── main.sh
├── packages.txt
├── preview
│   ├── audacious.png
│   ├── btop.png
│   ├── cava.png
│   ├── colorscheme.png
│   ├── cursor.png
│   ├── dolphin.png
│   ├── fastfetch.png
│   ├── fish.png
│   ├── harunarc.png
│   ├── kitty.png
│   ├── launcher.png
│   ├── MangoHud.png
│   ├── plasmashell.png
│   ├── power.png
│   ├── ProFontIIx.png
│   ├── systray.png
│   └── wallpaper.png -> /home/caue/dotfiles/wallpapers/f18950144.png
├── preview.sh
├── README.md
├── setup_chaotic.sh
├── setup.sh
└── wallpapers
    └── f18950144.png
```

---

# Main Execution Flow

Full runtime:

```text
setup.sh
│
├── cleanup old temp sessions
├── clone repo into /tmp
├── check dependencies
├── calls main menu
| ...
├── exit
├── cleanup installed dependencys
└── cleanup current temp session
```
---

# [setup.sh](./setup.sh)

Main entrypoint.

Run:

```bash
curl -fsSL https://raw.githubusercontent.com/cauezinho2008/dotfiles/main/setup.sh | bash
```

---

## What it does

### Cleanup old sessions

Deletes:

```text
/tmp/cauedotfiles-*
```

before creating a new session.

This prevents stale installs.

---

### Clone repo

Creates:

```text
/tmp/cauedotfiles-XXXX
```

and clones repo there.

All scripts run inside this temp folder.

---

### Detect distro

Reads:

```bash
/etc/os-release
```

Used for package manager support.

Supports:

* pacman
* apt
* dnf

---

### Dependency check

Checks:

```text
gum
fzf
chafa
git
curl
```

Installs missing ones.

Tracks what it installed.

At exit:

asks if temporary dependencies should be removed.

---

# [main.sh](./main.sh)

the actual menu

Uses gum to launch:

* [setup_chaotic.sh](#setup_chaoticsh)
* [install_apps.sh](#install_appssh)
* [copy_dotfiles.sh](#copy_dotfilessh)
* [appearance.sh](#appearancesh)
<img width="331" height="294" alt="image" src="https://github.com/user-attachments/assets/6645e758-c9a3-4dc2-ab68-5b02b6c5f5e3" />

---

# [setup_chaotic.sh](setup_chaotic.sh)

>[!NOTE]
>this entry only appears in arch based systems

Sets up Chaotic-AUR.

Needed for packages that exist there.
And i like it

Flow:

```text
install keyring
↓
install mirrorlist
↓
add repo to pacman.conf
↓
refresh databases
```

https://aur.chaotic.cx/

---

# [install_apps.sh](install_apps.sh)

This installs apps.

Unlike other modules, it does NOT scan directories.

It reads:

[packages.txt](./packages.txt)

---

## How it works

Each line:

one package.

Example:

```text
kitty
fish
fastfetch
btop
cava
```

Flow:

```text
read packages.txt
↓
ignore empty lines/comments
↓
build package list
↓
show selector in fzf
↓
install selected packages
```

Uses detected package manager.

---


# [copy_dotfiles.sh](copy_dotfiles.sh)

Main config applier.

Scans:

[.config](.config)
[.local/share](.local/share)
[hooks](hooks)

Builds one unified selector.

---

## Scanning logic

Uses:

```bash
find "$dir" -mindepth 1 -maxdepth 1
```

Example:

```text
.config/fish
.config/kitty
.config/fastfetch
```

becomes:

```text
fish
kitty
fastfetch
```

---

## Hook entries


Scans:

```text
hooks/*.sh
```

and strips:

```text
.sh
```

Example:

```text
hooks/power.sh
```

becomes:

```text
power
```

This allows virtual entries.


## Hooks System

Hooks are post-copy executors.

Pattern:

```text
hooks/<name>.sh
```

If selected entry matches:

runs automatically.

Flow:

```text
copy config
↓
check hooks/<name>.sh
↓
run if exists
```

Example:

```text
kitty
↓
copy config
↓
run hooks/kitty.sh
↓
reload kitty live
```

---

## Preview generation

Uses:

**⤷   [preview.sh](#previewsh)**

Execution flow:

```text
copy_dotfiles.sh
↓
build selector
↓
open fzf
↓
fzf spawns preview.sh in subshell
↓
preview.sh resolves matching file
↓
renders preview
```

This updates live while moving selection.

---

## Apply flow

```text
backup selected entries
↓
copy files
↓
check matching hook
↓
run hook
```

Example:

```text
fish
↓
copies .config/fish
↓
runs hooks/fish.sh
```




# appearance.sh

Visual-only installer.

Separate from dotfiles.

Scans:

```text
appearance/
```

and sorts using:

```text
appearance_order.txt
```

---

## Flow

```text
scan scripts
↓
read order
↓
build selector
↓
preview selected item
↓
confirmation
↓
apply
```

Confirmation:

```text
This will override your current configs.
This cannot be undone.
```

---

## Preview generation

Same preview system:

➡ preview.sh

Matching by filename.

Example:

```text
colorscheme
```

looks for:

```text
preview/colorscheme.png
preview/colorscheme.txt
```

---

# Appearance Modules

---

## colorscheme.sh

Copies:

```text
.local/share/color-schemes/
```

Applies:

```bash
plasma-apply-colorscheme
```

---

## wallpaper.sh

Hardcoded.

Copies and applies the default wallpaper.

Current behavior:

single wallpaper only.

Not multi-choice.

Uses:

```bash
plasma-apply-wallpaperimage
```

---

## kwin.sh

Copies:

```text
kwinrc
kwinrulesrc
```

Reloads KWin.

Applies:

* effects
* borders
* behavior

---

## plasmashell.sh

Copies:

```text
plasma-org.kde.plasma.desktop-appletsrc
plasmashellrc
```

Reloads:

```bash
kstart5 plasmashell
```

Restores:

* panels
* widgets
* tray layout

---

## launcher.sh

Restores favorite launcher apps.

Handled through Plasma config.

---

## cursor.sh

Downloads cursor theme.

Installs into:

```text
/usr/share/icons/
```

or:

```text
~/.icons/
```

Applies for:

* Plasma
* Wayland
* X11
* XWayland

---

## fonts.sh

Downloads Nerd Fonts.

Installs:

* system-wide
* user-only

Refreshes font cache.

---

# [preview.sh](preview.sh)

Shared preview engine.

Used by:

* [copy_dotfiles.sh](#copy_dotfilessh)
* [appearance.sh](#appearancesh)

Runs inside fzf preview subshell.

---

## Resolution logic

Receives:

```text
preview.sh fish
```

Searches:

```text
preview/fish.*
```

Priority:

```text
fish.txt
fish.png
fish.jpg
fish.webp
```

---

## Full flow

```text
fzf selection
↓
spawn preview.sh
↓
resolve filename
↓
if txt exists → show text
↓
if image exists → show image
↓
update live
```

---

## Rendering stack

Text:

```text
bat
```

fallback:

```text
cat
```

Images:

```text
chafa
```

inside fzf pane.

---




# excluded.txt

Used by dotfiles.

Hides grouped config files.

Example:

```text
kwinrc
plasmarc
kdeglobals
powerdevilrc
```

Reason:

these are managed by hooks or appearance modules.

Prevents duplicates.

---

# Temporary Sessions

Everything runs in:

```text
/tmp/
```

Startup:

deletes old sessions.

Exit:

deletes current session.

Prevents:

* clutter
* broken partial installs
* stale files

---

# Dependency Handling

Tracks installed dependencies.

Only removes what it installed.

Never removes user-installed packages.

Tracked in:

```bash
INSTALLED_NOW=()
```

At exit:

asks:

```text
Remove temporary dependencies?
```

---

# How to Extend

Add dotfiles:

```text
.config/myconfig
hooks/myconfig.sh
preview/myconfig.png
```

Automatically works.

---

Add appearance module:

```text
appearance/mytheme.sh
preview/mytheme.png
```

Add name into:

```text
appearance_order.txt
```

Done.

---

Add app descriptions:

```text
preview/kitty.txt
preview/fish.txt
```

Done.

---

This entire repository scales by **naming convention**.

That is the core architecture.
