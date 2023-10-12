# w11-nonadmin-utils

w11-nonadmin-utils is an interactive command line tool to change settings and install programs on Windows 11, without needing acess to an administrator account or the settings app. This is useful in cases where you are a restricted user, like on a school computer, but still want to set things up in a way that is comfortable for you.

---

## Features

These are features that are fully ready.

- [x] Sytem theming:
  - [x] Set system to dark mode.
  - [x] Change the background image.
  - [x] Change mouse trail length.
  - [x] Change mouse cursor style
  - [x] Enable and disable transparency effects
  - [x] Edit date and time display
    - [x] Change date and time formats
    - [x] Use long time in taskbar (may only work on versions newer than 22H2)
  - [x] Disable animation effects
  - [x] Disable notifications

- [x] Taskbar settings:
  - [x] Move the start menu back to the left.
  - [x] Move the taskbar. (Does not work on 22H2 or later, you can use [ExplorerPatcher](https://github.com/valinet/ExplorerPatcher/releases) if you have admin rights to install it.)
  - [x] Unpin task view, widgets, chat, and search from the taskbar.
  - [x] Disable web search in start menu

- [x] Input settings:
  - [x] Change the keyboard layout (only Dvorak and Qwerty for now)
  - [x] Set the mouse speed.
  - [x] Disable sticky keys prompt
  - [x] Enable find cursor

- [x] Install programs:
  - [x] Install [FireFox](https://www.mozilla.org/en-US/firefox/new/)
  - [x] Install [PowerToys](https://github.com/microsoft/PowerToys)
  - [x] Install [Visual Studio Code](https://github.com/microsoft/vscode)
  - [x] Install [Cygwin64](https://www.cygwin.com/)
  - [x] Install [clavier plus](https://github.com/guilryder/clavier-plus)

- [x] Command line utilities
  - [x] Add and remove items from bin
  - [x] Install [fastfetch](https://github.com/LinusDierheimer/fastfetch)
  - [x] Install [ntop](https://github.com/gsass1/NTop)
  - [x] Install [btop4win](https://github.com/aristocratos/btop4win)
  - [x] Install [gping](https://github.com/orf/gping)

## Beta features

These are features are in the release, but do not work entirely as intended.

- [x] Uninstall programs (Some programs may need admin to uninstall, Will not uninstall the built in apps. Use something like [Windows10Debloater](https://github.com/Sycnex/Windows10Debloater) to do that)
- [x] Install [lapce](https://github.com/lapce/lapce) (Needs visual c++)

## Alpha features

These are features that are not yet in the realease. These features may not work as intended. They may be removed at any time.

- [ ] Install [eDEX-UI](https://github.com/GitSquared/edex-ui)
- [ ] Install [genact](https://github.com/svenstaro/genact)

## Planned features

These are features that have no code yet, but are planned for the future. There is no garuntee that these features will be added.

- [ ] Install [kalker](https://github.com/PaddiM8/kalker)
- [ ] Install [Cura](https://github.com/Ultimaker/Cura/)
- [ ] [Disable windows copilot](https://allthings.how/how-to-disable-copilot-on-windows-11/)
- [ ] All the text editors ([vim](https://github.com/vim/vim), [neovim](https://github.com/neovim/neovim), [micro](https://github.com/zyedidia/micro), [nano](https://github.com/lhmouse/nano-win))
- [ ] DOOM! Perhaps [this version?](https://github.com/wojciech-graj/doom-ascii)
- [ ] [browsr](https://github.com/juftin/browsr)

---

## WARNINGS:

THIS SCRIPT MAKES CHANGES TO THE REGISTRY. USE AT YOUR OWN RISK.

This script is made for windows 11, it may work on other versions, or it may not

---

## To use the script

If you have admin rights, open an admin PowerShell window and create a system restore point, replacing the drive name as needed:

```PowerShell
Enable-ComputerRestore -Drive "C:\" ; Checkpoint-Computer -Description "w11-nonadmin-utils script run" -RestorePointType "MODIFY_SETTINGS"
```

### Quick run:

Open PowerShell and run this command: 

```PowerShell
iwr "https://github.com/starchyunderscore/w11-nonadmin-utils/releases/download/00.01.18/setup.ps1" | iex
```

### Quick run, alpha version ( WARNING: unstable, may not work, may break things ):

Open PowerShell and run this command:

```PowerShell
iwr "https://raw.githubusercontent.com/starchyunderscore/w11-nonadmin-utils/main/current/setup.ps1" | iex
```

### Run locally:

Download the latest setup.ps1 file from the [releases page](https://github.com/starchyunderscore/w11-nonadmin-utils/releases/latest)

Run the below command in PowerShell, replacing the path to `setup.ps1` as needed

```PowerShell
PowerShell -ep Bypass -File ~\Downloads\setup.ps1
```

---

See [here](https://github.com/starchyunderscore/w11-nonadmin-utils/blob/main/current/GUI-setup.ps1) for progress on the GUI version
