# w11-nonadmin-utils
An interactive command line tool to change settings and install programs in windows 11, without needing admin rights.

## WARNINGS:

THIS SCRIPT MAKES CHANGES TO THE REGISTRY. USE AT YOUR OWN RISK.

This script is made for windows 11, it may work on other versions, or it may not

## What the script can do

- [x] Set system to dark mode.
- [x] Move the start menu back to the left.
- [x] Unpin chat from taskbar.
- [x] Unpin widgets from taskbar.
- [x] Unpin search from the taskbar.
- [x] Unpin task view from the search bar.
- [x] Set the mouse speed.
- [x] Install FireFox.
- [x] Set the keyboard layout to dvorak.
- [x] Install PowerToys.
- [x] Move the taskbar. (Does not work on 22H2 or later, you can use [ExplorerPatcher](https://github.com/valinet/ExplorerPatcher/releases) if you have admin rights to install it.)
- [x] Install Visual Studio Code.
- [x] Change the background image. 

## What I have planned for the future

- [ ] Uninstall programs (10%)
- [ ] Install [lapce](https://github.com/lapce/lapce) (30%)

## To use the script

Download the latest setup.ps1 file from the [releases page](https://github.com/starchyunderscore/w11-nonadmin-utils/releases/latest)

If you have admin rights, open an admin powershell window and create a system restore point:

```
Enable-ComputerRestore -Drive "C:\"
Checkpoint-Computer -Description "noadmin utils script run" -RestorePointType "MODIFY_SETTINGS"
```

Run the below command in powershell, replacing the path to `setup.ps1` as needed

```
powershell -ep Bypass -File .\Downloads\setup.ps1
```
