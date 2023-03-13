# Try to create a restore point
try {
  Enable-ComputerRestore -Drive "C:\"
  Checkpoint-Computer -Description "starchyunderscore/windows11-setupscript" -RestorePointType "MODIFY_SETTINGS"
  Write-Host "`nRestore point created sucsessfully." -ForegroundColor Green
} catch {
  # If restore point fails, warn user and ask if they wish to continue regardless.
  Write-Host "`n!!!!!!!!!!`nWARNING: A RESTORE POINT COULD NOT BE CREATED. ANY BREAKAGES MAY BE PERMANENT`n!!!!!!!!!!`n" -ForegroundColor Yellow
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
                Write-Host "`nCanceled." -ForegroundColor Magenta
              }
              1 {
                Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 0
                Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Value 0
                Write-Host "`nDark mode applied, restarting explorer." -ForegroundColor Green
                Get-Process explorer | Stop-Process
              }
              2 {
                Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 1
                Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Value 1
                Write-Host "`nLight mode applied, restarting explorer." -ForegroundColor Green
                Get-Process explorer | Stop-Process
              }
            }
          }
          2 { # Change the background image
$setwallpapersrc = @"
using System.Runtime.InteropServices;
public class Wallpaper
{
  public const int SetDesktopWallpaper = 20;
  public const int UpdateIniFile = 0x01;
  public const int SendWinIniChange = 0x02;
  [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
  private static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
  public static void SetWallpaper(string path)
  {
    SystemParametersInfo(SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange);
  }
}
"@
            Add-Type -TypeDefinition $setwallpapersrc

            Write-Host '`nTo get the image path of a file, right click it and select "Copy as path"' -ForegroundColor Yellow
            Write-Host "`nMake sure your image path is in quotes!`n" -ForegroundColor Yellow
            $IMGPath = Read-Host "Input the full path of the image to set the wallpaper, or leave it blank to cancel"

            if($IMGPath -notmatch "\S") {
              Write-Host "`nCanceled.`n" -ForegroundColor Magenta
            } else {
              [Wallpaper]::SetWallpaper($IMGPath)
              Write-Host "`nSet background image to $IMGPath.`n" -ForegroundColor Green
            }
          }
        }
      } until ($Themer -notmatch "\S")
    }
    2 { # Change taskbar settings
      DO {
        # Print choices
        Write-Host "`n1. Move the start menu"
        Write-Host "2. Move the taskbar"
        Write-Host "3. Pin and unpin items"
        # Prompt user for choice
        $Tbar = Read-Host "`nInput the number of an option from the list above, or leave blank to exit"
        switch ($Tbar) {
          1 { # Move the start menu
            $leftStartMenu = $Host.UI.PromptForChoice("Selecet start menu location preference:", "", @("&Cancel", "&Left", "&Center"), 0)
            switch ($leftStartMenu) {
              0 {
                Write-Host "`nCanceled." -ForegroundColor Magenta
              }
              1 {
                try{Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarAl' -Value 0} catch{New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarAl' -Value 0 -PropertyType Dword}
                Write-Host "`nLeft start menu applied." -ForegroundColor Green
              }
              2 {
                try{Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarAl' -Value 1} catch{} # default is to be center alligned, therefore do nothing if registry key does not exist
                Write-Host "`nCenter start menu applied." -ForegroundColor Green
              }
            }
          }
          2 { # Move the taskbar
            Write-Host "`nThis does not work on windows 11 version 22H2 or later!`n" -ForegroundColor Yellow
            $Location = $Host.UI.PromptForChoice("Select taskbar location preference.", "", @("&Bottom", "&Top", "&Left", "&Right"), 0)
              $bit = 0;
              switch ($Location) {
                2 { $bit = 0x00 } # Left
                3 { $bit = 0x02 } # Right
                1 { $bit = 0x01 } # Top
                0 { $bit = 0x03 } # Bottom
              }
              $Settings = (Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3 -Name Settings).Settings
              $Settings[12] = $bit
              Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3 -Name Settings -Value $Settings
              Write-Host "`nTaskbar moved, restarting explorer." -ForegroundColor Green
              Get-Process explorer | Stop-Process
          }
          3 { # Pin and unpin items
            DO {
              # List items that can be modified
              Write-Host "`n1. Modify task view"
              Write-Host "2. Modify widgets"
              Write-Host "3. Modify chat"
              Write-Host "4. Modify search"
              # Prompt user for choice
              $Tpins = Read-Host "`nInput the number of an option from the list above, or leave blank to exit"
              swich ($Tpins) {
                1 { # Task view
                  
                }
                2 { # Widgets
                  
                }
                3 { # Chat
                  
                }
                4 { # Search
                  
                }
              }
            } until ($Tpins -notmatch "\S")
          }
        }
      } until ($Tbar -notmatch "\S")
    }
    3 { # Change input settings
      
    }
    4 { # Install programs
      
    }
  }
} until ($Option -notmatch "\S")

Write-Host "`nScript Finished`n" -ForegroundColor Green
Exit 0
