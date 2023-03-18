# FUNCTIONS

function CREATE_BIN { # Create bin if it does not exist
  if (!(Test-Path "$HOME\bin")) {
    Write-Output "`nBin does not exist. Creating." -ForegroundColor Yellow
    mkdir $HOME\bin
    $env:Path += "$HOME\bin"
    if (!(Test-Path -Path $PROFILE.CurrentUserCurrentHost)) {
      New-Item -ItemType File -Path $PROFILE.CurrentUserCurrentHost -Force
    }
    Write-Output ';$env:Path += "$HOME\bin;";' >> $PROFILE.CurrentUserCurrentHost
    Write-Output "`nBin created"
  }
}

# SCRIPT

Write-Output "`n!!!!!!!!!!`nWARNING: THIS SCRIPT MAKE CHANGES TO THE REGISTRY, MAKE SURE YOU HAVE MADE A RESTORE POINT`n!!!!!!!!!!`n" -ForegroundColor Yellow
$ContinueScript = $Host.UI.PromptForChoice("Are you sure you want to continue?", "", @("&Yes", "&No"), 1)
if ($ContinueScript -eq 1) {
  Write-Output "`nUser quit`n" -ForegroundColor Red
  Exit 0
}

DO {
  # Print choices
  Write-Output "`n1. Change system theming"
  Write-Output "2. Change taskbar settings"
  Write-Output "3. Change input settings"
  Write-Output "4. Install programs"
  Write-Output "5. Uninstall programs"
  Write-Output "6. Command line utilites"
  # Prompt user for choice
  $Option = Read-Host "`nInput the number of an option from the list above, or leave blank to exit"
  # Do each thing depending on what the choice is
  switch ($Option) {
    1 { # Change system theming
      DO {
        # Print options
        Write-Output "`n1. Turn dark mode on or off"
        Write-Output "2. Change the background image"
        # Prompt user for choice
        $Themer = Read-Host "`nInput the number of an option from the list above, or leave blank to exit"
        switch ($Themer) {
          1 { # Turn dark mode on or off
            $useDarkMode = $Host.UI.PromptForChoice("Select system mode:", "", @("&Cancel", "&Dark mode", "&Light Mode"), 0)
            switch ($useDarkMode) {
              0 {
                Write-Output "`nCanceled." -ForegroundColor Magenta
              }
              1 {
                Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 0
                Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Value 0
                Write-Output "`nDark mode applied, restarting explorer." -ForegroundColor Green
                Get-Process explorer | Stop-Process
              }
              2 {
                Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 1
                Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Value 1
                Write-Output "`nLight mode applied, restarting explorer." -ForegroundColor Green
                Get-Process explorer | Stop-Process
              }
            }
          }
          2 { # Change the background image ( https://gist.github.com/s7ephen/714023 )
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

            Write-Output "`nTo get the image path of a file, right click it and select `"Copy as path`"" -ForegroundColor Yellow
            Write-Output "`nMake sure your image path is in quotes!`n" -ForegroundColor Yellow
            $IMGPath = Read-Host "Input the full path of the image to set the wallpaper, or leave it blank to cancel"

            if($IMGPath -notmatch "\S") {
              Write-Output "`nCanceled.`n" -ForegroundColor Magenta
            } else {
              [Wallpaper]::SetWallpaper($IMGPath)
              Write-Output "`nSet background image to $IMGPath.`n" -ForegroundColor Green
            }
          }
        }
      } until ($Themer -notmatch "\S")
    }
    2 { # Change taskbar settings
      DO {
        # Print choices
        Write-Output "`n1. Move the start menu"
        Write-Output "2. Move the taskbar"
        Write-Output "3. Pin and unpin items"
        # Prompt user for choice
        $Tbar = Read-Host "`nInput the number of an option from the list above, or leave blank to exit"
        switch ($Tbar) {
          1 { # Move the start menu
            $leftStartMenu = $Host.UI.PromptForChoice("Selecet start menu location preference:", "", @("&Cancel", "&Left", "&Middle"), 0)
            switch ($leftStartMenu) {
              0 {
                Write-Output "`nCanceled." -ForegroundColor Magenta
              }
              1 {
                try {
                  Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarAl' -Value 0
                } catch {
                  New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarAl' -Value 0 -PropertyType Dword
                }
                Write-Output "`nLeft start menu applied." -ForegroundColor Green
              }
              2 {
                try {
                  Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarAl' -Value 1
                } catch {Write-Error ""} # No registry item is same as default
                Write-Output "`nCenter start menu applied." -ForegroundColor Green
              }
            }
          }
          2 { # Move the taskbar
            Write-Output "`nThis does not work on windows 11 version 22H2 or later!`n" -ForegroundColor Yellow
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
              Write-Output "`nTaskbar moved, restarting explorer." -ForegroundColor Green
              Get-Process explorer | Stop-Process
          }
          3 { # Pin and unpin items ( https://github.com/Ccmexec/PowerShell/blob/master/Customize%20TaskBar%20and%20Start%20Windows%2011/CustomizeTaskbar.ps1 )
            DO {
              # List items that can be modified
              Write-Output "`n1. Modify task view"
              Write-Output "2. Modify widgets"
              Write-Output "3. Modify chat"
              Write-Output "4. Modify search"
              # Prompt user for choice
              $Tpins = Read-Host "`nInput the number of an option from the list above, or leave blank to exit"
              switch ($Tpins) {
                1 { # Task view
                  $IPinStatus = $Host.UI.PromptForChoice("Set task view pin status", "", @("&Cancel", "&Unpinned", "&Pinned"), 0)
                  switch ($IPinStatus) {
                    0 {
                      Write-Output "`nCanceled" -ForegroundColor Magenta
                    }
                    1 { # task view
                      try {
                        Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'ShowTaskViewButton' -Value 0
                      } catch {
                        New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'ShowTaskViewButton' -Value 0 -PropertyType DWord
                      }
                      Write-Output "`nTask view unpinned" -ForegroundColor Green
                    }
                    2 {
                      try {
                        Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'ShowTaskViewButton' -Value 1
                      } catch {Write-Error ""} # No registry item is same as default
                      Write-Output "`nTask view pinned" -ForegroundColor Green
                    }
                  }
                }
                2 { # Widgets
                  $IPinStatus = $Host.UI.PromptForChoice("Set widget pin status", "", @("&Cancel", "&Unpinned", "&Pinned"), 0)
                  switch ($IPinStatus) {
                    0 {
                      Write-Output "`nCanceled" -ForegroundColor Magenta
                    }
                    1 {
                      try {
                        Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarDa' -Value 0
                      } catch {
                        New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarDa' -Value 0 -PropertyType DWord
                      }
                      Write-Output "`nWidgets unpinned" -ForegroundColor Green
                    }
                    2 {
                      try {
                        Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarDa' -Value 1
                      } catch {Write-Error ""} # No registry item is same as default
                      Write-Output "`nWidgets pinned" -ForegroundColor Green
                    }
                  }
                }
                3 { # Chat
                  $IPinStatus = $Host.UI.PromptForChoice("Set chat pin status", "", @("&Cancel", "&Unpinned", "&Pinned"), 0)
                  switch ($IPinStatus) {
                    0 {
                      Write-Output "`nCanceled" -ForegroundColor Magenta
                    }
                    1 {
                      try {
                        Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarMn' -Value 0
                      } catch {
                        New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarMn' -Value 0 -PropertyType DWord
                      }
                      Write-Output "`nChat unpinned" -ForegroundColor Green
                    }
                    2 {
                      try {
                        Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarMn' -Value 1
                      } catch {Write-Error ""} # No registry item is same as default
                      Write-Output "`nChat pinned" -ForegroundColor Green
                    }
                  }
                }
                4 { # Search
                  $IPinStatus = $Host.UI.PromptForChoice("Set search bar pin status", "", @("&Cancel", "&Unpinned", "&Pinned"), 0)
                  switch ($IPinStatus) {
                    0 {
                      Write-Output "`nCanceled" -ForegroundColor Magenta
                    }
                    1 {
                      try {
                        Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search -Name 'SearchboxTaskbarMode' -Value 0
                      } catch {
                        New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search -Name 'SearchboxTaskbarMode' -Value 0 -PropertyType DWord
                      }
                      Write-Output "`nSearch bar unpinned" -ForegroundColor Green
                    }
                    2 {
                      try {
                        Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search -Name 'SearchboxTaskbarMode' -Value 1
                      } catch {Write-Error ""} # No registry item is same as default
                      Write-Output "`nSearch bar pinned" -ForegroundColor Green
                    }
                  }
                }
              }
            } until ($Tpins -notmatch "\S")
          }
        }
      } until ($Tbar -notmatch "\S")
    }
    3 { # Change input settings
      DO {
        # Print choices
        Write-Output "`n1. Change the keyboard layout"
        Write-Output "2. Change the mouse speed"
        # Prompt user for choice
        $Iset = Read-Host "`nInput the number of an option from the list above, or leave blank to exit"
        switch ($Iset) {
          1 { # Keyboard layout ( https://gist.github.com/DieBauer/997dc90701a137fce8be )
            # this part needs a rewrite later to make it easier to expand
            $KeyboardLayout = $Host.UI.PromptForChoice("Select the layout you want", "", @("&Cancel", "&qwerty en-US", "&dvorak en-US"), 0)
            $l = Get-WinUserLanguageList
            # http://stackoverflow.com/questions/167031/programatically-change-keyboard-to-dvorak
            # 0409:00010409 = dvorak en-US
            # 0409:00000409 = qwerty en-US
            switch ($KeyboardLayout) {
              0 {
                Write-Output "`nCancled" -ForegroundColor Magenta
              }
              1 {
                $l[0].InputMethodTips[0]="0409:00000409"
                Set-WinUserLanguageList -LanguageList $l
                Write-Output "`nqwerty en-US keyboard layout applied" -ForegroundColor Green
              }
              2 {
                $l[0].InputMethodTips[0]="0409:00010409"
                Set-WinUserLanguageList -LanguageList $l
                Write-Output "`nDvorak en-US keyboard layout applied" -ForegroundColor Green
              }
            }
          }
          2 { # Mouse speed ( https://renenyffenegger.ch/notes/Windows/PowerShell/examples/WinAPI/modify-mouse-speed )
            DO {
              Write-Output "`n10 is the default mouse speed of windows.`n" -ForegroundColor Yellow
              $MouseSpeed = Read-Host "Enter number from 1-20, or leave blank to ext"
              if ($MouseSpeed -In 1..20) {
                set-strictMode -version latest
                $winApi = add-type -name user32 -namespace tq84 -passThru -memberDefinition '
                   [DllImport("user32.dll")]
                    public static extern bool SystemParametersInfo(
                       uint uiAction,
                       uint uiParam ,
                       uint pvParam ,
                       uint fWinIni
                    );
                '
                $SPI_SETMOUSESPEED = 0x0071
                $null = $winApi::SystemParametersInfo($SPI_SETMOUSESPEED, 0, $MouseSpeed, 0)
                set-itemProperty 'hkcu:\Control Panel\Mouse' -name MouseSensitivity -value $MouseSpeed
                Write-Output "`nMouse speed set to $MouseSpeed" -ForegroundColor Green
              } elseif ($MouseSpeed -notmatch "\S") {
                Write-Output "`nCanceled" -ForegroundColor Magenta
              } else {
                Write-Output "`nThat input is out of range or not a number" -ForegroundColor Red
              }
            } until ($MouseSpeed -In 1..20 -Or $MouseSpeed -notmatch "\s")
          }
        }
      } until ($Iset -notmatch "\S")
    }
    4 { # Install programs
      DO {
        # List options
        Write-Output "`n1. FireFox"
        Write-Output "2. PowerToys"
        Write-Output "3. Visual Studio Code"
        Write-Output "4. Lapce"
        # Prompt user for input
        $PGram = Read-Host "`nInput the number of an option from the list above, or leave blank to exit"
        switch ($PGram) {
          1 { # FireFox
            $InstallFirefox = $Host.UI.PromptForChoice("Which version of firefox would you like to install?", "", @("&Cancel", "&Latest", "&Nightly", "&Beta", "&Dev", "&ESR"), 0)
            switch ($InstallFirefox -eq 1) {
              0 { # Cancel
                Write-Output "`nCanceled" -ForegroundColor Magenta
              }
              1 { # Latest
                Start-BitsTransfer -source "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US" -destination ".\FireFoxInstall.exe"
              }
              2 { # Nightly
                Start-BitsTransfer -source "https://download.mozilla.org/?product=firefox-nightly-latest-ssl&os=win64&lang=en-US" -destination ".\FireFoxInstall.exe"
              }
              3 { # Beta
                Start-BitsTransfer -source "https://download.mozilla.org/?product=firefox-beta-latest-ssl&os=win64&lang=en-US" -destination ".\FireFoxInstall.exe"
              }
              4 { # Dev
                Start-BitsTransfer -source "https://download.mozilla.org/?product=firefox-devedition-latest-ssl&os=win64&lang=en-US" -destination ".\FireFoxInstall.exe"
              }
              5 { # ESR
                Start-BitsTransfer -source "https://download.mozilla.org/?product=firefox-esr-latest-ssl&os=win64&lang=en-US" -destination ".\FireFoxInstall.exe"
              }
            }
            if ($InstallFirefox -In 1..5) { # For less repeated code
              Write-Output "`nYou can say `"no`" when it prompts to let the application make changes to your device, and it will still install.`n" -ForegroundColor Yellow
              .\FireFoxInstall.exe | Out-Null # so that it waits for the installer to complete before going on to the next command
              rm .\FireFoxInstall.exe
            }
          }
          2 { # PowerToys ( https://gist.github.com/laurinneff/b020737779072763628bc30814e67c1a )
            $InstallPowertoys = $Host.UI.PromptForChoice("Install Microsoft PowerToys?", "", @("&Cancel", "&Install"), 0)
            if ($InstallPowertoys -eq 1) {
              $installLocation = "$env:LocalAppData\Programs\PowerToys"

              $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) (New-Guid)
              New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
              Push-Location $tempDir

              $latestPowerToys = Invoke-WebRequest "https://api.github.com/repos/microsoft/PowerToys/releases/latest" | ConvertFrom-Json
              $latestVersion = $latestPowerToys.tag_name.Substring(1)
              $isInstalled = Test-Path "$installLocation\PowerToys.exe"
              if ($isInstalled) {
                $currentVersion = (Get-Item "$installLocation\PowerToys.exe").VersionInfo.FileVersion
                $currentVersion = $currentVersion.Substring(0, $currentVersion.LastIndexOf("."))
              }

              Write-Output "Latest: $latestVersion"
              if (!$isInstalled) {
                Write-Output "Current: Not installed"
              }
              else {
                Write-Output "Current: $currentVersion"
              }

              if ($isInstalled -and ($latestVersion -le $currentVersion)) {
                Write-Output "Already up to date"
                Pop-Location
                Remove-Item $tempDir -Force -Recurse
                Read-Host "Finished! Press enter to exit"
              } else {

                $latestPowerToys.assets | ForEach-Object {
                  $asset = $_
                  if ($asset.name -match "x64.exe$") {
                    $assetUrl = $asset.browser_download_url
                    $assetName = $asset.name
                  }
                }

                Write-Output "Downloading $assetName"
                Start-BitsTransfer $assetUrl "$assetName" # Start-BitsTransfer instead of Invoke-WebRequest here to get a fancy progress bar (also BitsTransfer feels faster, but idk if this is true)
                $powertoysInstaller = "$tempDir\$assetName"

                $latestWix = Invoke-WebRequest "https://api.github.com/repos/wixtoolset/wix3/releases/latest" | ConvertFrom-Json
                $latestWix.assets | ForEach-Object {
                  $asset = $_
                  if ($asset.name -match "binaries.zip$") {
                    $assetUrl = $asset.browser_download_url
                    $assetName = $asset.name
                  }
                }

                Write-Output "Downloading $assetName"
                Start-BitsTransfer $assetUrl "$assetName"
                $wixDir = "$tempDir\wix"
                Expand-Archive "$tempDir\$assetName" -DestinationPath $wixDir

                Write-Output "Extracting installer .exe"
                $extractedInstaller = "$tempDir\extractedInstaller"
                & "$wixDir\dark.exe" -x $extractedInstaller $powertoysInstaller | Out-Null

                $msi = Get-ChildItem $extractedInstaller\AttachedContainer\*.msi
                $extractedMsi = "$tempDir\extractedMsi"
                Write-Output "Extracting installer .msi"
                Start-Process -FilePath msiexec.exe -ArgumentList @( "/a", "$msi", "/qn", "TARGETDIR=$extractedMsi" ) -Wait

                Write-Output "Stopping old instance (if running)"
                Stop-Process -Name PowerToys -Force -ErrorAction SilentlyContinue
                Start-Sleep 5 # To make sure the old instance is stopped

                Write-Output "Installing new version"
                Remove-Item "$installLocation" -Recurse -Force -ErrorAction SilentlyContinue
                Copy-Item "$extractedMsi\PowerToys" -Destination $installLocation -Recurse

                Write-Output "Creating hardlinks for runtimes"
                # Code copy/pasted from https://github.com/ScoopInstaller/Extras/blob/0999a7377dd102c0f287ec191eed4866eb075562/bucket/powertoys.json#L24-L40
                foreach ($f in @('Settings', 'modules\FileLocksmith', 'modules\Hosts', 'modules\MeasureTool', 'modules\PowerRename')) {
                  Get-ChildItem -Path "$installLocation\dll\WinAppSDK\" | ForEach-Object {
                    New-Item -ItemType HardLink -Path "$installLocation\$f\$($_.Name)" -Value $_.FullName | Out-Null
                  }
                }
                foreach ($f in @('Settings', 'modules\Awake', 'modules\ColorPicker', 'modules\FancyZones',
                    'modules\FileExplorerPreview', 'modules\FileLocksmith', 'modules\Hosts', 'modules\ImageResizer',
                    'modules\launcher', 'modules\MeasureTool', 'modules\PowerAccent', 'modules\PowerOCR')) {
                  Get-ChildItem -Path "$installLocation\dll\Interop" | ForEach-Object {
                    New-Item -ItemType HardLink -Path "$installLocation\$f\$($_.Name)" -Value $_.FullName | Out-Null
                  }
                  Get-ChildItem -Path "$installLocation\dll\dotnet\" | ForEach-Object {
                    New-Item -ItemType HardLink -Path "$installLocation\$f\$($_.Name)" -Value $_.FullName -ErrorAction SilentlyContinue | Out-Null
                  }
                }

                Write-Output "Starting new instance"
                Start-Process "$installLocation\PowerToys.exe"

                if (!$isInstalled) {
                  $WshShell = New-Object -ComObject WScript.Shell

                  $createShortcut = $Host.UI.PromptForChoice("Create shortcut?", "Create a start menu shortcut for PowerToys?", @("&Yes", "&No"), 0)
                  if ($createShortcut -eq 0) {
                    $Shortcut = $WshShell.CreateShortcut("$env:AppData\Microsoft\Windows\Start Menu\Programs\PowerToys.lnk")
                    $Shortcut.TargetPath = "$installLocation\PowerToys.exe"
                    $Shortcut.Save()
                  }

                  $autostart = $Host.UI.PromptForChoice("Autostart?", "Start PowerToys automatically on login?", @("&Yes", "&No"), 0)
                  if ($autostart -eq 0) {
                    $Shortcut = $WshShell.CreateShortcut("$env:AppData\Microsoft\Windows\Start Menu\Programs\Startup\PowerToys.lnk")
                    $Shortcut.TargetPath = "$installLocation\PowerToys.exe"
                    $Shortcut.Save()
                  }
                }

                Write-Output "Cleaning up"
                Pop-Location
                Remove-Item -Path $tempDir -Recurse -Force

                Write-Output "`nFinished installing powertoys!" -ForegroundColor Green
              }
            } else {
              Write-Output "`nCanceled" -ForegroundColor Magenta
            }
          }
          3 { # Visual Studio Code
            $InstallVSC = $Host.UI.PromptForChoice("Install visual studio code?", "", @("&Cancel", "&Install"), 0)
            if($InstallVSC -eq 1) {
              Set-ExecutionPolicy Bypass -Scope Process -Force;
              $remoteFile = 'https://go.microsoft.com/fwlink/?Linkid=850641';
              $downloadFile = $env:Temp+'\vscode.zip';
              $vscodePath = $env:LOCALAPPDATA+"\VsCode";

              Start-BitsTransfer -source "$remoteFile" -destination "$downloadFile"

              Expand-Archive $downloadFile -DestinationPath $vscodePath -Force
              [Environment]::SetEnvironmentVariable
              ("Path", $env:Path, [System.EnvironmentVariableTarget]::User);

              $WshShell = New-Object -ComObject WScript.Shell
              $Shortcut = $WshShell.CreateShortcut("$env:AppData\Microsoft\Windows\Start Menu\Programs\Visual Studio Code.lnk")
              $Shortcut.TargetPath = "$env:LOCALAPPDATA\VsCode\Code.exe"
              $Shortcut.Save()
              Write-Output "`nVisual Studio Code installed" -ForegroundColor Green
            } else {
              Write-Output "`nCancled" -ForegroundColor Magenta
            }
          }
          4 { # Lapce
            $InstallLapce = $Host.UI.PromptForChoice("Install Lapce?", "", @("&Cancel", "&Install"), 0)
            if ($InstallLapce -eq 1) {
              Write-Output "`nWARNING, THIS PROGRAM DOES NOT INSTALL CORRECTLY IN THIS VERSION`n" -ForegroundColor Yellow

              $latestLapce = Invoke-WebRequest "https://api.github.com/repos/lapce/lapce/releases/latest" | ConvertFrom-Json
              $latestVersion = $latestLapce.tag_name.Substring(1)
              Start-BitsTransfer -source "https://github.com/lapce/lapce/releases/download/v$latestVersion/Lapce-windows-portable.zip" -destination ".\Lapce-windows-portable.zip"
              Expand-Archive ".\Lapce-windows-portable.zip" -DestinationPath "$env:LOCALAPPDATA\Lapce" -Force | Out-Null # So it waits to move on to the next one
              rm ".\Lapce-windows-portable.zip"

              $WshShell = New-Object -ComObject WScript.Shell
              $Shortcut = $WshShell.CreateShortcut("$env:AppData\Microsoft\Windows\Start Menu\Programs\Lapce.lnk")
              $Shortcut.TargetPath = "$env:LOCALAPPDATA\Lapce\lapce.exe"
              $Shortcut.Save()
              Write-Output "`nLapce installed" -ForegroundColor Green
            }
          }
        }
      } until ($PGram -notmatch "\S")
    }
    5 { # Uninstall programs
      # DO THIS NEXT
      Write-Output "`nNot done yet!!`n" -ForegroundColor Yellow
      DO {
        Write-Output "`n1. List installed programs"
        Write-Output "2. Uninstall a program"
        $UninsPgam = Read-Host "`nInput the number of an option from the list above, or leave blank to exit"
        switch ($UninsPgam) {
          1 { # List installed
            Write-Output "`nIDK I've not done this bit yet" -ForegroundColor Yellow
          }
          2 { # Uninstall something
            Write-Output "`nOops this bit has not been added yet" -ForegroundColor Yellow
          }
        }
      } until ($UninsPgam -notmatch "\S")
    }
    6 { # Command line utilities
      DO {
        # List options
        Write-Output "`n1. Add items to bin"
        Write-Output "2. Install fastfetch" # May be replaced in the future I just wanted there to be more than one item here
        # Prompt user for input
        $CLUtils = Read-Host "`nInput the number of an option from the list above, or leave blank to exit"
        switch ($CLUtils) {
          1 { # Add items to bin
            # THIS WHOLE THING NEEDS TO BE REWORDED
            CREATE_BIN
            # Inform user how to exit
            Write-Output "Leaving either prompt blank will not add anything"
            # Prompt user
            $BinAddItem = Read-Host "`nInput path of item"
            if ($BinAddItem -notmatch "\S") {
              Write-Output "`nCanceled`n" -ForegroundColor Magenta
            } elseif (!(Test-Path $BinAddItem)) {
              Write-Output "`nItem does not exist`n" -ForegroundColor Red
            } else {
              $BinOperation = $Host.UI.PromptForChoice("How should the item be put in the bin", "", @("&Cancel", "&Move item", "&Link item"), 0)
              switch ($BinOperation) {
                0 { # Cancel
                  Write-Output "Canceled" -ForegroundColor Magenta
                }
                1 { # Move Item
                  mv $BinAddItem "$HOME\bin"
                }
                2 { # Link Item
                  $BinAddName = Read-Host "`nInput command you wish to have call item" # REWORD THIS
                  if ($BinAddName -notmatch "\S") {
                    Write-Output "Canceled" -ForegroundColor Magenta
                  } elseif (Test-Path -Path "$HOME\bin\$BinAddName`.exe" -Or Test-Path -Path "$HOME\bin\$BinAddName`.ps1" -Or Test-Path -Path "$HOME\bin\$BinAddName`.lnk") {
                    Write-Output "Item with that name already exists in bin" -ForegroundColor Red
                  } else {
                    $WshShell = New-Object -ComObject WScript.Shell
                    $Shortcut = $WshShell.CreateShortcut("$HOME\bin\$BinAddName.lnk")
                    $Shortcut.TargetPath = "$BinAddItem"
                    $Shortcut.Save()
                  }
                }
              }
            }
          }
          2 { # Get fastfetch
            CREATE_BIN
            # Actually install it
            Start-BitsTransfer -source "https://github.com/LinusDierheimer/fastfetch/releases/download/1.10.3/fastfetch-1.10.3-Win64.zip" -destination ".\fastfetch.zip"
            Expand-Archive ".\fastfetch.zip" -DestinationPath ".\fastfetch" -Force
            mv ".\fastfetch\fastfetch.exe" "$HOME\bin" | Out-Null # Just in case
            rm ".\fastfetch.zip"
            rm ".\fastfetch" -r
          }
        }
      } until ($CLUtils -notmatch "\S")
    }
  }
} until ($Option -notmatch "\S")

Write-Output "`nScript Finished`n" -ForegroundColor Green
Exit 0
