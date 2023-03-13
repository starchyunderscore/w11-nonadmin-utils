# Try to create a restore point
try {
  Enable-ComputerRestore -Drive "C:\"
  Checkpoint-Computer -Description "starchyunderscore/windows11-setupscript" -RestorePointType "MODIFY_SETTINGS"
  Write-Host "`nRestore point created sucsessfully." -ForegroundColor Green
} catch {
  # If restore point fails, warn user and ask if they wish to continue regardless.
  Write-Host "`n!!!!!!!!!!`nWARNING: A RESTORE POINT COULD NOT BE CREATED. ANY BREAKAGES MAY BE PERMANENT.`n!!!!!!!!!!`n" -ForegroundColor Yellow
  $ContinueScript = $Host.UI.PromptForChoice("Are you sure you want to continue?", "", @("&Yes", "&No"), 1)
  if ($ContinueScript -eq 1) {
    Write-Host "`nUser quit`n" -ForegroundColor Red
    Exit 0
  }
}

DO {
  # Print choices
  Write-Host "`n1. Change system theming"
  Write-Host "2. Change taskbar settings"
  Write-Host "3. Change input settings"
  Write-Host "4. Install programs"
  # Prompt user for choice
  $Option = Read-Host "`nInput the number of an option from the list above, or leave blank to exit"
  # Do each thing depending on what the choice is
  switch ($Option) {
    1 { # Change system theming
      DO {
        # Print options
        Write-Host "`n1. Turn dark mode on or off"
        Write-Host "2. Change the background image"
        # Prompt user for choice
        $Themer = Read-Host "`nInput the number of an option from the list above, or leave blank to exit"
        switch ($Themer) {
          1 { # Turn dark mode on or off
            $useDarkMode = $Host.UI.PromptForChoice("Select system mode:", "", @("&Cancel", "&Dark mode", "&Light Mode"), 0)
            switch($useDarkMode) {
              0 {
                Write-Host "`nCanceling" -ForegroundColor Magenta
              }
              1 {
                Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 0
                Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Value 0
                Write-Host "`nDark mode applied, restarting explorer" -ForegroundColor Green
                Get-Process explorer | Stop-Process
              }
              2 {
                Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 1
                Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Value 1
                Write-Host "`nLight mode applied, restarting explorer" -ForegroundColor Green
                Get-Process explorer | Stop-Process
              }
            }
          }
          2 { # Change the background image
            
          }
        }
      } until ($Themer -notmatch "\S")
    }
  }
} until ($Option -notmatch "\S")

Write-Host "`nScript Finished`n" -ForegroundColor Green
Exit 0
