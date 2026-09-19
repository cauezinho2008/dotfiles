# AGENTS.md

Personal dotfiles repo for **Arch-based (CachyOS) + KDE Plasma** on this machine. Not a library — everything here is runner-tested by the owner. There is no test suite; `bash -n <script>` is the lint.

## Entrypoint & how it executes

- `setup.sh` is the real entrypoint. It **clones the live GitHub repo** (`https://github.com/cauezinho2008/dotfiles.git`, `main` branch) into `/tmp/cauedotfiles-*` and runs `main.sh` from that temp clone.
- Consequence: editing a script locally has **no effect until you `git push` and re-run `setup.sh`** — the temp clone pulls from origin.
- `main.sh` is the interactive menu. Module scripts: `kde.sh` (appearance), `copy_dotfiles.sh` (config apply), `install_apps.sh` (packages), `setup_chaotic.sh`, `boot.sh`.
- Some menu entries reference scripts not present in the repo (e.g. "Restore backup" → `restore_backup.sh`). Missing ones are detected and skipped with a "Script not found." message — do not assume a menu item implies a file exists.

## Modular naming convention (the whole architecture)

One config name = union of same-named paths — `copy_dotfiles.sh` scans them with `find` (maxdepth 1) and keys everything by `basename`:

- `.config/<name>` → copied to `~/.config/`
- `.local/share/<name>` → copied to `~/.local/share/`
- `hooks/<name>.sh` → executed after the copy (also bare-name fallback)
- `preview/<name>.*` → shown by `preview.sh` (txt via `bat`, images via `chafa`)

To add a config, drop the folder under `.config/` (and/or `.local/share/`); it appears in the picker automatically — no registry to edit.

## Non-obvious wiring

- **Hooks run after copies**: on apply, copy the dirs, then look for `hooks/<name>.sh` (fallback strips trailing `rc`: `hooks/${name%rc}.sh`), and `bash` it if present.commands like `kitty @ set-colors` live here.
- **Order files**: `appearance/order.txt` and `boot/order.txt` define the order KDE/boot modules are applied (each `<name>` maps to `appearance/<name>.sh` / `boot/<name>.sh`).
- **`excluded.txt`** lines are skipped by the dotfile registry (e.g. `kwinrc`, `plasmarc`, `dolphinrc` are system/Plasma-managed and must not be offered). Add entries here to hide a config from the picker instead of deleting it.
- **Secrets in configs**: this repo is **public**. Configs that store API keys (SteamGridDB `steamgriddb-api-key` in `faugus-launcher`/`millennium` configs) must have the key **blanked before committing**. The live `~/.config` keeps the real key; the repo copy is redacted.
- **Copy is destructive**: `cp -a` overwrites `~/.config` / `~/.local/share` with no backup in `copy_dotfiles.sh`. Restores/backups are handled by separate modules only.
- Machine-specific data (`.local/share/faugus-launcher` game covers/banners, `.local/state/*`) is intentionally **not** tracked — only settings.

## Commands / tooling

- Deps used by scripts: `gum`, `fzf`, `chafa`, `bat`. KDE appearance apply depends on Plasma-KDE tools (`kwriteconfig6`, `plasma-apply-*`).
- Lint: `bash -n` every touch script.
- Apply flow — distro-gated: `install_apps.sh` is **pacman/Arch-only** and exits on other distros; appearance modules are KDE-only.
- When syncing a live config back into the repo, use `cp -a` (preserves modes) and re-blank any API keys before `git commit`.

## Style

- `#!/usr/bin/env bash`, `set -euo pipefail`.
- Blue accent constants (`#6A9EFF` gum theme) are exported at the top of each menu script — keep them consistent if you touch a UI file.
- Scripts are interactive (gum/fzf); they `clear` and expect a TTY — don't run them non-interactively.
