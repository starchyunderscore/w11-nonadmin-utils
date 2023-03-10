# ask user about backups
$ContinueScript = $Host.UI.PromptForChoice("WARNING: THIS SCRIPT MESSES WITH THE REGISTRY. CREATE A RESTORE POINT, THINGS COULD BREAK! Are you sure you want to continue?", "(Default N)", @("&Y", "&N"), 1)
if ($ContinueScript -eq 1) {
	Exit "user quit"
}
# starting text
Write-Host "Starting script."
Write-Host "!! MAKE SURE TO CAREFULLY READ ALL PROMPTS !!"
# set dark mode preference
$useDarkMode = $Host.UI.PromptForChoice("Set the system to dark mode?", "(Default Y)", @("&Y", "&N"), 0)
if ($useDarkMode -eq 0) {
	Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 0
	Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Value 0
	Write-Host "Dark mode applied"
} else {
	Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 1
	Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Value 1
	Write-Host "Light mode applied"
}
# set start menu location preference
$leftStartMenu = $Host.UI.PromptForChoice("Start menu on left side?", "(Default Y)", @("&Y", "&N"), 0)
if ($leftStartMenu -eq 0) {
	try{Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarAl' -Value 0} catch{New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarAl' -Value 0 -PropertyType Dword}
	Write-Host "Left start menu applied"
} else {
	try{Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarAl' -Value 1} catch{} # default is to be center alligned, therefore do nothing if registry key does not exist
	Write-Host "Center start menu applied"
}
# chat and widget unpins taken from https://github.com/Ccmexec/PowerShell/blob/master/Customize%20TaskBar%20and%20Start%20Windows%2011/CustomizeTaskbar.ps1
# unpin chat from taskbar
$unpinChat = $Host.UI.PromptForChoice("Unpin chat?", "(Default Y)", @("&Y", "&N"), 0)
if ($unpinChat -eq 0) {
	try{Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarMn' -Value 0} catch{New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarMn' -Value 0 -PropertyType DWord}
	Write-Host "Chat unpinned"
} else {
	try{Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarMn' -Value 1} catch{} # default is to be pinned, therefore do nothing if registry key does not exist
	Write-Host "Chat pinned"
}
# unpin widgets from taskbar
$unpinWidgets = $Host.UI.PromptForChoice("Unpin widgets?", "(Default Y)", @("&Y", "&N"), 0)
if ($unpinWidgets -eq 0) {
	try{Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarDa' -Value 0} catch{New-itemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarDa' -Value 0 -PropertyType DWord}
	Write-Host "Widgets unpinned"
} else {
	try{Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarDa' -Value 0} catch{} # default is pinned widgets, therefore do nothing if registry key does not exis
	Write-Host "Widgets pinned"
}
# set mouse speed ( taken from https://renenyffenegger.ch/notes/Windows/PowerShell/examples/WinAPI/modify-mouse-speed )
$SetMouseSpeed = $Host.UI.PromptForChoice("Set the mouse speed?", "(Default N)", @("&Y", "&N"), 1)
if ($SetMouseSpeed -eq 0) {
	Write-Host "10 is the default mouse speed of windows."
	$MouseSpeed = Read-Host "Enter number from 1-20"
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
		Write-Host "Mouse speed set to $MouseSpeed"
	} else {
		Write-Host "ERROR: That number is out of range or not a number."
	}
}
# install firefox
$InstallFirefox = $Host.UI.PromptForChoice("Install Firefox?", "(Default Y)", @("&Y", "&N"), 0)
if ($InstallFirefox -eq 0) {
try{winget install Mozilla.Firefox} catch{
	Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
	winget install Mozilla.Firefox
}
Write-Host "FireFox installed"
}
# switch keyboard ( taken from https://gist.github.com/DieBauer/997dc90701a137fce8be )
$SwitchKeyboard = $Host.UI.PromptForChoice("Switch to the dvorak keyboard layout?", "(Default N)", @("&Y", "&N"), 1)
if ($SwitchKeyboard -eq 0) {
	$KeyboardLayout = $Host.UI.PromptForChoice("Select the layout you want", "(Default cancel)", @("&cancel", "&qwerty_en_US", "&dvorak_en_US"), 0)
	$l = Get-WinUserLanguageList
	# http://stackoverflow.com/questions/167031/programatically-change-keyboard-to-dvorak
	# 0409:00010409 = dvorak en-US
	# 0409:00000409 = qwerty en-US
	switch($KeyboardLayout) {
		0 {
			Write-Host "Operation Cancled"
		}
		1 {
			$l[0].InputMethodTips[0]="0409:00000409"
			Set-WinUserLanguageList -LanguageList $l
			Write-Host "qwerty en-US keyboard layout applied"
		}
		2 {
			$l[0].InputMethodTips[0]="0409:00010409"
			Set-WinUserLanguageList -LanguageList $l
			Write-Host "Dvorak keyboard layout applied"
		}
	}
}
# install powertoys ( taken form https://gist.github.com/laurinneff/b020737779072763628bc30814e67c1a )
$InstallPowertoys = $Host.UI.PromptForChoice("Install Microsoft PowerToys?", "(Default Y)", @("&Y", "&N"), 0)
if ($InstallPowertoys -eq 0) {
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
	exit
}

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

Write-Host "Finished installing powertoys!"
}
# taskbar location ( taken from https://blog.ironmansoftware.com/daily-powershell/windows-11-taskbar-location/ )
$TaskbarLocation = $Host.UI.PromptForChoice("Move taskbar?", "(Default N)", @("&Y", "&N"), 1)
if ($TaskbarLocation -eq 0) {
$Location = $Host.UI.PromptForChoice("Where should the taskbar go?", "(Default Bottom)", @("Bottom", "&Top", "&Left", "&Right"), 0)
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
	Write-Host "Taskbar moved, restarting explorer"
	Get-Process explorer | Stop-Process
}
# end script
Read-Host "Script Finished, press enter to exit"
