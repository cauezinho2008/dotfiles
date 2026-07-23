
# Cauê's Dotfiles

<img width="1920" height="1080" alt="Screenshot_20260624_152022" src="https://github.com/user-attachments/assets/35c2df4e-88e5-46a6-b452-89e149596343" />

More preview images can be found in the [`/preview`](./preview) folder.

This is my personal arsenal of scripts to apply my dotfiles, themes, cursor, fonts, power profiles, Plasma settings, and other related tweaks.

I made this mostly for myself, so I can restore my entire OS state quickly after reinstalling or testing new systems — but if you like my ricing, feel free to use it.

It includes:

* Dotfiles installer
* Plasma appearance presets
* Color schemes
* Wallpapers
* Cursor installer
* Font installer
* Power profiles
* App presets
* Custom hooks for applying configs

## Installation

You don’t need to manually install dependencies.

The installer handles everything automatically:

* downloads itself into a temporary folder
* installs any required dependencies
* runs all scripts from there
* removes temporary files after finishing
* can remove temporary dependencies if they were only needed for installation
* **some modules may require `sudo` for system-wide installation (fonts, cursor themes, power profiles, etc.)**


To run it:

```bash
curl -fsSL https://raw.githubusercontent.com/cauezinho2008/dotfiles/main/setup.sh | bash
```

This launches the interactive installer

<img width="836" height="561" alt="image" src="https://github.com/user-attachments/assets/bfe7e5e1-7a42-4c8f-9de4-3c5675d2400b" />


where you can:

* install my app selection
* apply dotfiles
* apply KDE appearance presets
* install cursor themes
* install fonts
* configure power profiles
* restore most of my system setup in a few minutes

Everything is modular, so you can choose only what you want.


it also features previews of currently selected item trought the [`/preview`](./preview) folder:

<img width="795" height="460" alt="Screenshot_20260712_094055" src="https://github.com/user-attachments/assets/8ef711fe-cc1b-40c2-9ae5-792561552088" />

> [!NOTE]
> Its recommended to reboot after installation,
> as some changes (especially Plasma themes, fonts, cursor themes, and power-related settings) may require you to **reboot** fully apply.



## How this was made

This whole project was built with a mix of **Bash**, **Gum**, and **fzf**.

I’m not a developer — this started as a personal way to rebuild my system faster, and slowly turned into a modular installer for my entire setup.

Basically all the code was build with help from Chatgpt, but how it works, the logic, testing and problem fixing was all done by myself

### Stack used

* **Bash** → core scripting and automation
* **Gum** → menus, confirmations, styling, and interactive UI
* **fzf** → multi-selection menus and previews
* **Chafa** → image previews inside terminal
* **KDE tools** (`kwriteconfig6`, `plasma-apply-colorscheme`, etc.) → applying desktop configs live

### How it works

The installer downloads itself into a temporary directory and builds its menus dynamically.

Each section is modular:

* **Apps** → installs packages
* **Dotfiles** → copies configs and runs hooks
* **Appearance** → applies themes, wallpapers, Plasma configs, and more
* **Hooks** → run extra commands needed after copying configs

Everything is split into folders so it’s easy to maintain, expand, or selectively apply.

For a full breakdown of every script and how each section works, check:

➡ **[Documentation](documentation.md)**


## Notes

* Built mainly for **KDE Plasma**
* Designed around my own workflow and app selection
* Works best on **Arch-based distros** (especially CachyOS)
* Some scripts may require `sudo`


## License

This project is licensed under the MIT License — see the [LICENSE](./LICENSE) file.
