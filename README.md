# windows11-setupscript
A powershell setup script that can be run with no admin rights, to set up computers how I want them to be.

## WARNINGS:

### BEWARE! THIS SCRIPT MAKES CHANGES TO THE REGISTRY. MAKE SURE YOU HAVE A BACKUP BEFORE RUNNING IT!

#### This script is made for windows 11, it may work on other versions, or it may not

## Context / why I made it

We have computers at my school where the user (us, the students) have almost no rights. We do not have admin. We do not have acess to settings, we do not have acess to files, &c.

One thing we do have acess to, though, is powershell. Though we cannot change the execution policy to run scripts, I have written this one in a way that it should be able to run if you just copy/paste it directly into the terminal.

This script is mostly tailored to my preferences, though I have added prompts to each individual aspect, and set defaults according to what I think the majority of people will want.

## What the script can do

- [x] Set system to dark mode.
- [x] Move the start menu back to the left.
- [x] Unpin chat from taskbar.
- [x] Unpin widgets from taskbar.
- [x] Set the mouse speed.
- [x] Install FireFox.
- [x] Set the keyboard layout to dvorak.
- [x] Install PowerToys.

## To use the script

Download the \[releasenum\]\_setup.ps1 file from the [releases page](https://github.com/starchyunderscore/windows11-setupscript/releases)

Open up a new terminal window, it will be powershell by default.

If you have the permissions to, create a system restore point:

```
Enable-ComputerRestore -Drive "C:\"
Checkpoint-Computer -Description "setup script run" -RestorePointType "MODIFY_SETTINGS"
```

unblock the file and run the it

```
cd .\[where the file is]\
Unblock-File -Path .\[releasenum]_setup.ps1
.\[releasenum]_setup.ps1
```

if you do not have permission to unblock files, open \[releasenum\]\_setup.ps1 in a text editor, copy the entire thing, and paste it into the terminal
