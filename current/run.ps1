<#
  This script is intended to be hosted on a short domain so that the setup script can be run quickly by typing, for example "iwr w11n.au | iex".
  Of course, I don't live in Australia, and the script has no connection to it, and I can't afford that domain anyways, but it's a cool idea.
  The only place I could theoretically host it is starchyunderscore.github.io, but that's really long to type as well.
  Slightly shorter than what you would have to type to run the script now, sure, but still very long.
  I'm looking at free name services, but none of them are super great.
  I'm also trying to see if you can have more than one site on github pages, so that this could be hosted via github instead of some other service.
  Hopefully, assuming this script works and I can find everything I need, there should be an easy way to run the setup script "soon"
#>
Write-Output "!! THIS SCRIPT IS NOT TESTED, USE ONE OF THE METHODS LISTED IN THE README !!"
Write-Output "!! THIS SCRIPT IS NOT TESTED, USE ONE OF THE METHODS LISTED IN THE README !!"
Write-Output "!! THIS SCRIPT IS NOT TESTED, USE ONE OF THE METHODS LISTED IN THE README !!"
Write-Output "!! THIS SCRIPT IS NOT TESTED, USE ONE OF THE METHODS LISTED IN THE README !!"
Write-Output "!! THIS SCRIPT IS NOT TESTED, USE ONE OF THE METHODS LISTED IN THE README !!`n`n`n"
# Check if the user is running an admin powershell window
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  # Create restore point if the user wants to
  $restore = $Host.UI.PromptForChoice("Would you like to create a restore point? (Requires admin)", "", @("&Yes","&No"), 0)
  if ($restore -eq 0) {
    Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -Command `"Enable-ComputerRestore -Drive C:\ ; Checkpoint-Computer -Description w11-nonadmin-utils_script_run -RestorePointType MODIFY_SETTINGS`""
  } else {
    Write-Output "Skipping"
  }
  # Get latest version information
  Write-Output "`nFetching latest version information"
  $getLatest = Invoke-WebRequest -UseBasicParsing "https://api.github.com/repos/starchyunderscore/w11-nonadmin-utils/releases/latest" | ConvertFrom-Json
  $latest = $getLatest.tag_name.Substring(0)
  # Ask what the user wants to do
  $rundl = $Host.UI.PromptForChoice("", "", @("&Cancel", "&Run", "&Download"), 0)
  switch ($rundl) {
    0 { # Cancel
      Write-Output "`nCanceled"
    }
    1 { # Run
      $runver = $Host.UI.PromptForChoice("Which version would you like to run", "", @("&Cancel", "&Latest", "&Alpha"), 0)
      switch ($runver) {
        0 { # Cancel
          Write-Output "`nCanceled"
        }
        1 { # Latest
          Write-Output "Downloading"
          Write-Output "Running"
           Invoke-webRequest -UseBasicParsing "https://github.com/starchyunderscore/w11-nonadmin-utils/releases/download/$latest/setup.ps1" | Invoke-Expression
          Write-Output "Done"
        }
        2 { # Alpha
          Write-Output "Downloading"
          Write-Output "Running"
           Invoke-webRequest -UseBasicParsing "https://raw.githubusercontent.com/starchyunderscore/w11-nonadmin-utils/main/current/setup.ps1" | Invoke-Expression
          Write-Output "Done"
        }
      }
    }
    2 { # Download
      $dwnld = $Host.UI.PromptForChoice("Which version would you like to download", "", @("&Cancel", "&Latest", "&Alpha"), 0)
      switch ($dwnld) {
        0 { # Cancel
          Write-Output "Canceled"
        }
        1 { # Latest version
          $savelc = Read-Host "Input save location (including filename), or leave blank to cancel"
          if($savelc -notmatch "\S") {
            Write-Output "Canceled"
          } else {
            Write-Output "Downloading"
             Invoke-webRequest -UseBasicParsing "https://github.com/starchyunderscore/w11-nonadmin-utils/releases/download/$latest/setup.ps1" > $savelc
            Write-Output "Done"
          }
        }
        2 { # Alpha version
          $savelc = Read-Host "Input save location (including filename), or leave blank to cancel"
          if($savelc -notmatch "\S") {
            Write-Output "Canceled"
          } else {
            Write-Output "Downloading"
             Invoke-webRequest -UseBasicParsing "https://raw.githubusercontent.com/starchyunderscore/w11-nonadmin-utils/main/current/setup.ps1" > $savelc
            Write-Output "Done"
          }
        }
      }
    }
  }
} else {
  # Tell the user not to use an admin powershell window
  Write-Output "You shouldn't run the script in an admin Powershell window. Anything that needs admin will self-elevate."
}
# Ask if user wants to exit powershell
$leave = $Host.UI.PromptForChoice("Exit powershell window?", "", @("&Yes", "&No"), 0)
if ($leave -eq 0) {
  exit
}
