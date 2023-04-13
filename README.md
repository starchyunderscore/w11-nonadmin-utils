# w11-nonadmin-utils

An interactive command line tool to change settings and install programs in windows 11, without needing admin rights.

---

## WARNINGS:

THIS SCRIPT MAKES CHANGES TO THE REGISTRY. USE AT YOUR OWN RISK.

This script is made for windows 11, it may work on other versions, or it may not

---

## Features

These are features that are fully ready.

- [x] Set system to dark mode.
- [x] Move the start menu back to the left.
- [x] Unpin chat from taskbar.
- [x] Unpin widgets from taskbar.
- [x] Unpin search from the taskbar.
- [x] Unpin task view from the search bar.
- [x] Set the mouse speed.
- [x] Install [FireFox](https://www.mozilla.org/en-US/firefox/new/).
- [x] Set the keyboard layout to dvorak.
- [x] Install [PowerToys](https://github.com/microsoft/PowerToys).
- [x] Move the taskbar. (Does not work on 22H2 or later, you can use [ExplorerPatcher](https://github.com/valinet/ExplorerPatcher/releases) if you have admin rights to install it.)
- [x] Install [Visual Studio Code](https://github.com/microsoft/vscode).
- [x] Change the background image.
- [x] Install [fastfetch](https://github.com/LinusDierheimer/fastfetch).
- [x] Add and remove items from bin.
- [x] Change mouse trail length.
- [x] [Change cursor](https://stackoverflow.com/a/60107014)

## Beta features

These are features that work, but are imperfect.

- [x] Uninstall programs (Some programs may need admin to uninstall.) (Will not uninstall the built in apps. Use something like [Windows10Debloater](https://github.com/Sycnex/Windows10Debloater) to do that)

## Alpha features

These are features that are not yet in the realease, or are commented out.  They can be tried by copying the code or uncommenting them. These may be removed at any time.

- [ ] Install [lapce](https://github.com/lapce/lapce) (Needs visual c++ to be installed, but that cannot be installed without admin. Working on a fix.)

# Planned features

These are features that have no code yet, but are planned for the future. There is no garuntee that these features will be added.

- [ ] Install [WSL](https://learn.microsoft.com/en-us/windows/wsl/install)
- [ ] Install [OpenSSH](https://github.com/PowerShell/Win32-OpenSSH)

---

## To use the script

If you have admin rights, open an admin PowerShell window and create a system restore point:

```
Enable-ComputerRestore -Drive "C:\"
Checkpoint-Computer -Description "noadmin utils script run" -RestorePointType "MODIFY_SETTINGS"
```

Quick run:

Open PowerShell and run this command: 

```
iwr https://github.com/starchyunderscore/w11-nonadmin-utils/releases/download/00.01.06/setup.ps1 | iex
```

Quick run, alpha version ( WARNING: unstable, may not work, may break things ):

Open PowerShell and run this command:

```
iwr https://raw.githubusercontent.com/starchyunderscore/w11-nonadmin-utils/main/setup.ps1 | iex
```

Run with ability to edit script:

Download the latest setup.ps1 file from the [releases page](https://github.com/starchyunderscore/w11-nonadmin-utils/releases/latest)

Run the below command in PowerShell, replacing the path to `setup.ps1` as needed

```
PowerShell -ep Bypass -File ~\Downloads\setup.ps1
```
