# w11-nonadmin-utils

An interactive command line tool to change settings and install programs in windows 11, without needing admin rights.

---

See [here](https://github.com/starchyunderscore/w11-nonadmin-utils/blob/main/current/GUI-setup.ps1) for progress on the [GUI](https://theitbros.com/powershell-gui-for-scripts/) version

---

## WARNINGS:

THIS SCRIPT MAKES CHANGES TO THE REGISTRY. USE AT YOUR OWN RISK.

This script is made for windows 11, it may work on other versions, or it may not

---

## Features

These are features that are fully ready.

- [x] Sytem theming:
  - [x] Set system to dark mode.
  - [x] Change the background image.
  - [x] Change mouse trail length.
  - [x] [Change cursor](https://stackoverflow.com/a/60107014)
  - [x] Enable and disable transparency effects
  - [x] Change date and time format
- [x] Taskbar settings:
  - [x] Move the start menu back to the left.
  - [x] Unpin chat, widgets, and search from the taskbar.
  - [x] Unpin task view from the search bar.
  - [x] Move the taskbar. (Does not work on 22H2 or later, you can use [ExplorerPatcher](https://github.com/valinet/ExplorerPatcher/releases) if you have admin rights to install it.)

- [x] Input settings:
  - [x] Set the mouse speed.
  - [x] Change the keyboard layout (only Dvorak and Querty for now)
  - [x] [Disable sticky keys prompt](https://stackoverflow.com/questions/71854200/disable-shift-stickykey-shortcut)

- [x] Install programs:
  - [x] Install [FireFox](https://www.mozilla.org/en-US/firefox/new/).
  - [x] Install [PowerToys](https://github.com/microsoft/PowerToys).
  - [x] Install [Visual Studio Code](https://github.com/microsoft/vscode).

- [x] Command line utilities
  - [x] Install [fastfetch](https://github.com/LinusDierheimer/fastfetch).
  - [x] Add and remove items from bin.

## Beta features

These are features that work, but are imperfect.

- [x] Uninstall programs (Some programs may need admin to uninstall.) (Will not uninstall the built in apps. Use something like [Windows10Debloater](https://github.com/Sycnex/Windows10Debloater) to do that)

## Alpha features

These are features that are not yet in the realease, or are commented out.  They can be tried by copying the code or uncommenting them. These may be removed at any time. There is no garuntee that they will stay in the script.

- [ ] Install [lapce](https://github.com/lapce/lapce) (Needs visual c++ to be installed, but that cannot be installed without admin. Working on a fix.)
- [ ] Use long time in taskbar (may only work on versions newer than 22H2)
- [ ] Use old start menu (broken)

# Planned features

These are features that have no code yet, but are planned for the future. There is no garuntee that these features will be added.

- [ ] Install [Oracle VM VirtualBox](https://www.virtualbox.org/) (needs visual c++ and some way to run the exe --extract without admin)
- [ ] Install [clavier plus](https://github.com/guilryder/clavier-plus)
- [ ] Enable/Disable/Change animation effects
- [ ] Install [kalker](https://github.com/PaddiM8/kalker)

---

## To use the script

If you have admin rights, open an admin PowerShell window and create a system restore point, replacing the drive name as needed:

```PowerShell
Enable-ComputerRestore -Drive "C:\"
Checkpoint-Computer -Description "w11-nonadmin-utils script run" -RestorePointType "MODIFY_SETTINGS"
```

### Quick run:

Open PowerShell and run this command: 

```PowerShell
iwr "https://github.com/starchyunderscore/w11-nonadmin-utils/releases/download/00.01.11/setup.ps1" | iex
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
