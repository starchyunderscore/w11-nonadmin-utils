# windows11-setupscript
A setup script for windows 11 that does not require admin rights.

## WARNINGS:

### BEWARE! THIS SCRIPT MAKES CHANGES TO THE REGISTRY. MAKE SURE YOU HAVE A BACKUP BEFORE RUNNING IT!

#### This script is made for windows 11, it may work on other versions, or it may not

## What the script can do

- [x] Set system to dark mode.
- [x] Move the start menu back to the left.
- [x] Unpin chat from taskbar.
- [x] Unpin widgets from taskbar.
- [x] Set the mouse speed.
- [x] Install FireFox.
- [x] Set the keyboard layout to dvorak.
- [x] Install PowerToys.
- [x] Move the taskbar.

## To use the script

Download the latest setup.ps1 file from the [releases page](https://github.com/starchyunderscore/windows11-setupscript/releases/latest)

If you have admin rights, open an admin powershell window and create a system restore point:

```
Enable-ComputerRestore -Drive "C:\"
Checkpoint-Computer -Description "setup script run" -RestorePointType "MODIFY_SETTINGS"
```

Open up standard windows terminal or powershell, ***NOT*** command prompt.

Unblock the file and run it:

```
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
cd .\Downloads\
Unblock-File -Path .\setup.ps1
.\setup.ps1
```
