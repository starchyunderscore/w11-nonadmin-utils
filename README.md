# windows11-setupscript
A powershell setup script that can be run with no admin rights, to set up computers how I want them to be.

## WARNINGS:

### BEWARE! THOUGH THE INDIVIDUAL PARTS OF THIS SCRIPT HAVE BEEN TESTED, THE SCRIPT AS A WHOLE HAS NOT BEEN. USE AT YOUR OWN RISK.

### BEWARE! THIS SCRIPT MAKES CHANGES TO THE REGISTRY. MAKE SURE YOU HAVE A BACKUP BEFORE RUNNING IT!

## Context / why I made it

We have computers at my school where the user (us, the students) have almost no rights. We do not have admin. We do not have acess to settings, we do not have acess to files, &c.

One thing we do have acess to, though, is powershell. Though we cannot change the execution policy to run scripts, I have written this one in a way that it should be able to run if you just copy/paste it directly into the terminal.

This script is mostly tailored to my preferences, though I have added prompts to each individual aspect, and set defaults according to what I think the majority of people will want.

## To use the script

Create a system restore point

Open up the windows terminal, or powershell, **NOT** command prompt

Either run the script file (setup.ps1) , or copy/paste the whole script into the terminal.

Read and answer the prompts
