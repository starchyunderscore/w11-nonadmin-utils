# FUNCTIONS
function CREATE_BIN {
  if (!(Test-Path "$HOME\bin")) {
    Write-Output "`nBin does not exist. Creating."
    mkdir $HOME\bin
    $env:Path += ";$HOME\bin;"
    if (!(Test-Path -Path $PROFILE.CurrentUserCurrentHost)) {
      New-Item -ItemType File -Path $PROFILE.CurrentUserCurrentHost -Force
    }
    Write-Output ';$env:Path += ";$HOME\bin;";' >> $PROFILE.CurrentUserCurrentHost
    $CurrentPolicy = Get-ExecutionPolicy -Scope CurrentUser
    if ($CurrentPolicy -eq "Default" -or $CurrentPolicy -eq "AllSigned" -or $CurrentPolicy -eq "Restricted" -or $CurrentPolicy -eq "Undefined") {
      Write-Output "`nExecution policy needs to change to allow bin to work properly"
      Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
    }
    Write-Output "`nBin created"
  }
}
function UPDATE_USERPREFERENCESMASK {
                $Signature = @"
[DllImport("user32.dll", EntryPoint = "SystemParametersInfo")]
public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, uint pvParam, uint fWinIni);

const int SPI_SETCURSORS = 0x0057;
const int SPIF_UPDATEINIFILE = 0x01;
const int SPIF_SENDCHANGE = 0x02;

public static void UpdateUserPreferencesMask() {
    SystemParametersInfo(SPI_SETCURSORS, 0, 0, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
}
"@
                  Add-Type -MemberDefinition $Signature -Name UserPreferencesMaskSPI -Namespace User32
                  [User32.UserPreferencesMaskSPI]::UpdateUserPreferencesMask()
              }
Add-Type -Namespace demo -Name StickyKeys -MemberDefinition '
  [DllImport("user32.dll", SetLastError = true)]
  [return: MarshalAs(UnmanagedType.Bool)]
  static extern bool SystemParametersInfo(uint uiAction, uint uiParam, ref STICKYKEYS pvParam, uint fWinIni);
  [StructLayout(LayoutKind.Sequential)]
  struct STICKYKEYS {
    public uint  cbSize;
    public UInt32 dwFlags;
  }
  [Flags]
  public enum StickyKeyFlags : uint {
    AUDIBLEFEEDBACK = 0x00000040,
    AVAILABLE = 0x00000002,
    CONFIRMHOTKEY = 0x00000008,
    HOTKEYACTIVE = 0x00000004,
    HOTKEYSOUND = 0x00000010,
    INDICATOR = 0x00000020,
    STICKYKEYSON = 0x00000001,
    TRISTATE = 0x00000080,
    TWOKEYSOFF = 0x00000100,
    LALTLATCHED = 0x10000000,
    LCTLLATCHED = 0x04000000,
    LSHIFTLATCHED = 0x01000000,
    RALTLATCHED = 0x20000000,
    RCTLLATCHED = 0x08000000,
    RSHIFTLATCHED = 0x02000000,
    LALTLOCKED = 0x00100000,
    LCTLLOCKED = 0x00040000,
    LSHIFTLOCKED = 0x00010000,
    RALTLOCKED = 0x00200000,
    RCTLLOCKED = 0x00080000,
    RSHIFTLOCKED = 0x00020000,
    LWINLATCHED = 0x40000000,
    RWINLATCHED = 0x80000000,
    LWINLOCKED = 0x00400000,
    RWINLOCKED = 0x00800000
  }
  public static bool IsHotKeyEnabled {
    get { return (GetFlags() & StickyKeyFlags.HOTKEYACTIVE) != 0u; }
    set { EnableHotKey(value, false); }
  }
  public static StickyKeyFlags ActiveFlags {
    get { return GetFlags(); }
    set { SetFlags(value, false); }
  }
  // The flags in effect on a pristine system.
  public static StickyKeyFlags DefaultFlags {
    get { return StickyKeyFlags.AVAILABLE | StickyKeyFlags.HOTKEYACTIVE | StickyKeyFlags.CONFIRMHOTKEY | StickyKeyFlags.HOTKEYSOUND | StickyKeyFlags.INDICATOR | StickyKeyFlags.AUDIBLEFEEDBACK | StickyKeyFlags.TRISTATE | StickyKeyFlags.TWOKEYSOFF; } // 510u
  }
  public static void EnableHotKey(bool enable = true, bool persist = false) {
    var skInfo = new STICKYKEYS();
    skInfo.cbSize = (uint)Marshal.SizeOf(skInfo);
    var flags = GetFlags();
    SetFlags((enable ? flags | StickyKeyFlags.HOTKEYACTIVE : flags & ~StickyKeyFlags.HOTKEYACTIVE), persist);
  }
  private static StickyKeyFlags GetFlags() {
    var skInfo = new STICKYKEYS();
    skInfo.cbSize = (uint)Marshal.SizeOf(skInfo);
    if (!SystemParametersInfo(0x003a /* SPI_GETSTICKYKEYS */, 0, ref skInfo, 0))
      throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
    return (StickyKeyFlags)skInfo.dwFlags;
  }
  public static void SetFlags(StickyKeyFlags flags, bool persist = false) {
    var skInfo = new STICKYKEYS();
    skInfo.cbSize = (uint)Marshal.SizeOf(skInfo);
    skInfo.dwFlags = (UInt32)flags;
    if (!SystemParametersInfo(0x003b /* SPI_SETSTICKYKEYS */, 0, ref skInfo, persist ? 1u : 0u))
      throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
  }
'
function Show-Notification {
    [cmdletbinding()]
    Param (
        [string]
        $ToastTitle,
        [string]
        $ToastText
    )

    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
    $Template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)

    $RawXml = [xml] $Template.GetXml()
    ($RawXml.toast.visual.binding.text | Where-Object {$_.id -eq "1"}).AppendChild($RawXml.CreateTextNode($ToastTitle)) > $null
    ($RawXml.toast.visual.binding.text | Where-Object {$_.id -eq "2"}).AppendChild($RawXml.CreateTextNode($ToastText)) > $null

    $SerializedXml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $SerializedXml.LoadXml($RawXml.OuterXml)

    $Toast = [Windows.UI.Notifications.ToastNotification]::new($SerializedXml)
    $Toast.Tag = "PowerShell"
    $Toast.Group = "PowerShell"
    $Toast.ExpirationTime = [DateTimeOffset]::Now.AddMinutes(1)

    $Notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("PowerShell")
    $Notifier.Show($Toast);
}
# SCRIPT
Write-Output "`n!!!!!!!!!!`nWARNING: THIS SCRIPT MAKE CHANGES TO THE REGISTRY, MAKE SURE YOU HAVE MADE A RESTORE POINT`n!!!!!!!!!!`n"
$ContinueScript = $Host.UI.PromptForChoice("Are you sure you want to continue?", "", @("&Yes", "&No"), 1)
if ($ContinueScript -eq 1) {
  Write-Output "`nUser quit`n"
} else {
  # Small setup
  if (Test-Path $HOME\w11-nau-temp) {
    rm -r $HOME\w11-nau-temp
  }
  mkdir $HOME\w11-nau-temp
  $ProgressPreference = 'SilentlyContinue'
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
          Write-Output "3. Change mouse trails length"
          Write-Output "4. Change mouse cursor style"
          Write-Output "5. Enable/disable transparency effects"
          Write-Output "6. Edit date and time display"
          Write-Output "7. Enable/disable animation effects"
          Write-Output "8. Enable/disable notifications"
          # Prompt user for choice
          $Themer = Read-Host "`nInput the number of an option from the list above, or leave blank to exit"
          switch ($Themer) {
            1 { # Turn dark mode on or off
              $useDarkMode = $Host.UI.PromptForChoice("Select system mode:", "", @("&Cancel", "&Dark mode", "&Light Mode"), 0)
              switch ($useDarkMode) {
                0 {
                  Write-Output "`nCanceled."
                }
                1 {
                  Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 0
                  Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Value 0
                  Write-Output "`nDark mode applied, attempting to restart explorer."
                  try {Get-Process explorer | Stop-Process} catch {Write-Output "Explorer restart failed: changes will apply after a restart"}
                }
                2 {
                  Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 1
                  Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Value 1
                  Write-Output "`nLight mode applied, attempting to restart explorer."
                  try {Get-Process explorer | Stop-Process} catch {Write-Output "Explorer restart failed: changes will apply after a restart"}
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
              Write-Output "`nTo get the image path of a file, right click it and select `"Copy as path`"`n`nMake sure your image path is in quotes!`n"
              $IMGPath = Read-Host "Input the full path of the image to set the wallpaper, or leave it blank to cancel"
              if($IMGPath -notmatch "\S") {
                Write-Output "`nCanceled.`n"
              } else {
                [Wallpaper]::SetWallpaper($IMGPath)
                Write-Output "`nSet background image to $IMGPath.`n"
              }
            }
            3 { # Mouse trail length
              $Mtrail = Read-Host "Input a number from 0 (no trail) to 7 (long trail), or leave blank to exit"
              if ($Mtrail -In 0..7) {
                # https://www.makeuseof.com/windows-mouse-trail-enable-disable/#enable-or-disable-mouse-pointer-trails-using-the-registry-editor
                set-itemProperty 'hkcu:\Control Panel\Mouse' -name MouseTrails -value $Mtrail
                Write-Output "Mouse trail set to $Mtrail, attempting to restart explorer"
                try {Get-Process explorer | Stop-Process} catch {Write-Output "Explorer restart failed: changes will apply after a restart"}
              }
            }
            4 { # Cursor style
              Write-Output "`n1. Aero (Windows Default)"
              Write-Output "2. Aero l (Same as Aero, but larger)"
              Write-Output "3. Aero xl (Same as Aero, but extra large)"
              Write-Output "4. i (Old windows cursors)"
              Write-Output "5. il (Same as i, but extra large)"
              Write-Output "6. im (Same as i, but large)"
              Write-Output "7. l (Same as il)"
              Write-Output "8. m (Same as im)"
              Write-Output "9. r (Old windows cursor, dark mode edition)"
              Write-Output "10. rl (Same as r, but extra large)"
              Write-Output "11. rm (Same ar r, but large)"
              Write-Output "12. KDE Breeze Dark"
              $CStyle = Read-Host "`nInput the number of the style you wish to use, or leave blank to exit"
              if ($CStyle -In 1..12) {
                $RegConnect = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]"CurrentUser","$env:COMPUTERNAME")
                $RegCursors = $RegConnect.OpenSubKey("Control Panel\Cursors",$true)
                switch ($CStyle) {
                  1 { # Aero
                    $RegCursors.SetValue("","Windows Default")
                    $RegCursors.SetValue("AppStarting","C:\WINDOWS\cursors\aero_working.ani")
                    $RegCursors.SetValue("Arrow","C:\WINDOWS\cursors\aero_arrow.cur")
                    $RegCursors.SetValue("Crosshair","")
                    $RegCursors.SetValue("Hand","")
                    $RegCursors.SetValue("Help","C:\WINDOWS\cursors\aero_helpsel.cur")
                    $RegCursors.SetValue("IBeam","")
                    $RegCursors.SetValue("No","C:\WINDOWS\cursors\aero_unavail.cur")
                    $RegCursors.SetValue("NWPen","C:\WINDOWS\cursors\aero_pen.cur")
                    $RegCursors.SetValue("SizeAll","C:\WINDOWS\cursors\aero_move.cur")
                    $RegCursors.SetValue("SizeNESW","C:\WINDOWS\cursors\aero_nesw.cur")
                    $RegCursors.SetValue("SizeNS","C:\WINDOWS\cursors\aero_ns.cur")
                    $RegCursors.SetValue("SizeNWSE","C:\WINDOWS\cursors\aero_nwse.cur")
                    $RegCursors.SetValue("SizeWE","C:\WINDOWS\cursors\aero_ew.cur")
                    $RegCursors.SetValue("UpArrow","C:\WINDOWS\cursors\aero_up.cur")
                    $RegCursors.SetValue("Wait","C:\WINDOWS\cursors\aero_busy.ani")
                  }
                  2 { # Aero l
                    $RegCursors.SetValue("","Aero l")
                    $RegCursors.SetValue("AppStarting","C:\WINDOWS\cursors\aero_working_l.ani")
                    $RegCursors.SetValue("Arrow","C:\WINDOWS\cursors\aero_arrow_l.cur")
                    $RegCursors.SetValue("Crosshair","")
                    $RegCursors.SetValue("Hand","")
                    $RegCursors.SetValue("Help","C:\WINDOWS\cursors\aero_helpsel_l.cur")
                    $RegCursors.SetValue("IBeam","")
                    $RegCursors.SetValue("No","C:\WINDOWS\cursors\aero_unavail_l.cur")
                    $RegCursors.SetValue("NWPen","C:\WINDOWS\cursors\aero_pen_l.cur")
                    $RegCursors.SetValue("SizeAll","C:\WINDOWS\cursors\aero_move_l.cur")
                    $RegCursors.SetValue("SizeNESW","C:\WINDOWS\cursors\aero_nesw_l.cur")
                    $RegCursors.SetValue("SizeNS","C:\WINDOWS\cursors\aero_ns_l.cur")
                    $RegCursors.SetValue("SizeNWSE","C:\WINDOWS\cursors\aero_nwse_l.cur")
                    $RegCursors.SetValue("SizeWE","C:\WINDOWS\cursors\aero_ew_l.cur")
                    $RegCursors.SetValue("UpArrow","C:\WINDOWS\cursors\aero_up_l.cur")
                    $RegCursors.SetValue("Wait","C:\WINDOWS\cursors\aero_busy_l.ani")
                  }
                  3 { # Aero xl
                    $RegCursors.SetValue("","Aero xl")
                    $RegCursors.SetValue("AppStarting","C:\WINDOWS\cursors\aero_working_xl.ani")
                    $RegCursors.SetValue("Arrow","C:\WINDOWS\cursors\aero_arrow_xl.cur")
                    $RegCursors.SetValue("Crosshair","")
                    $RegCursors.SetValue("Hand","")
                    $RegCursors.SetValue("Help","C:\WINDOWS\cursors\aero_helpsel_xl.cur")
                    $RegCursors.SetValue("IBeam","")
                    $RegCursors.SetValue("No","C:\WINDOWS\cursors\aero_unavail_xl.cur")
                    $RegCursors.SetValue("NWPen","C:\WINDOWS\cursors\aero_pen_xl.cur")
                    $RegCursors.SetValue("SizeAll","C:\WINDOWS\cursors\aero_move_xl.cur")
                    $RegCursors.SetValue("SizeNESW","C:\WINDOWS\cursors\aero_nesw_xl.cur")
                    $RegCursors.SetValue("SizeNS","C:\WINDOWS\cursors\aero_ns_xl.cur")
                    $RegCursors.SetValue("SizeNWSE","C:\WINDOWS\cursors\aero_nwse_xl.cur")
                    $RegCursors.SetValue("SizeWE","C:\WINDOWS\cursors\aero_ew_xl.cur")
                    $RegCursors.SetValue("UpArrow","C:\WINDOWS\cursors\aero_up_xl.cur")
                    $RegCursors.SetValue("Wait","C:\WINDOWS\cursors\aero_busy_xl.ani")
                  }
                  4 { # i
                    $RegCursors.SetValue("","i")
                    $RegCursors.SetValue("AppStarting","C:\WINDOWS\cursors\wait_i.cur")
                    $RegCursors.SetValue("Arrow","C:\WINDOWS\cursors\arrow_i.cur")
                    $RegCursors.SetValue("Crosshair","C:\WINDOWS\cursors\cross_i.cur")
                    $RegCursors.SetValue("Hand","")
                    $RegCursors.SetValue("Help","C:\WINDOWS\cursors\help_i.cur")
                    $RegCursors.SetValue("IBeam","C:\WINDOWS\cursors\beam_i.cur")
                    $RegCursors.SetValue("No","C:\WINDOWS\cursors\no_i.cur")
                    $RegCursors.SetValue("NWPen","C:\WINDOWS\cursors\pen_i.cur")
                    $RegCursors.SetValue("SizeAll","C:\WINDOWS\cursors\move_i.cur")
                    $RegCursors.SetValue("SizeNESW","C:\WINDOWS\cursors\size1_i.cur")
                    $RegCursors.SetValue("SizeNS","C:\WINDOWS\cursors\size4_i.cur")
                    $RegCursors.SetValue("SizeNWSE","C:\WINDOWS\cursors\size2_i.cur")
                    $RegCursors.SetValue("SizeWE","C:\WINDOWS\cursors\size3_i.cur")
                    $RegCursors.SetValue("UpArrow","C:\WINDOWS\cursors\up_i.cur")
                    $RegCursors.SetValue("Wait","C:\WINDOWS\cursors\busy_i.cur")
                  }
                  5 { # il
                    $RegCursors.SetValue("","il")
                    $RegCursors.SetValue("AppStarting","C:\WINDOWS\cursors\wait_il.cur")
                    $RegCursors.SetValue("Arrow","C:\WINDOWS\cursors\arrow_il.cur")
                    $RegCursors.SetValue("Crosshair","C:\WINDOWS\cursors\cross_il.cur")
                    $RegCursors.SetValue("Hand","")
                    $RegCursors.SetValue("Help","C:\WINDOWS\cursors\help_il.cur")
                    $RegCursors.SetValue("IBeam","C:\WINDOWS\cursors\beam_il.cur")
                    $RegCursors.SetValue("No","C:\WINDOWS\cursors\no_il.cur")
                    $RegCursors.SetValue("NWPen","C:\WINDOWS\cursors\pen_il.cur")
                    $RegCursors.SetValue("SizeAll","C:\WINDOWS\cursors\move_il.cur")
                    $RegCursors.SetValue("SizeNESW","C:\WINDOWS\cursors\size1_il.cur")
                    $RegCursors.SetValue("SizeNS","C:\WINDOWS\cursors\size4_il.cur")
                    $RegCursors.SetValue("SizeNWSE","C:\WINDOWS\cursors\size2_il.cur")
                    $RegCursors.SetValue("SizeWE","C:\WINDOWS\cursors\size3_il.cur")
                    $RegCursors.SetValue("UpArrow","C:\WINDOWS\cursors\up_il.cur")
                    $RegCursors.SetValue("Wait","C:\WINDOWS\cursors\busy_il.cur")
                  }
                  6 { # im
                    $RegCursors.SetValue("","im")
                    $RegCursors.SetValue("AppStarting","C:\WINDOWS\cursors\wait_im.cur")
                    $RegCursors.SetValue("Arrow","C:\WINDOWS\cursors\arrow_im.cur")
                    $RegCursors.SetValue("Crosshair","C:\WINDOWS\cursors\cross_im.cur")
                    $RegCursors.SetValue("Hand","")
                    $RegCursors.SetValue("Help","C:\WINDOWS\cursors\help_im.cur")
                    $RegCursors.SetValue("IBeam","C:\WINDOWS\cursors\beam_im.cur")
                    $RegCursors.SetValue("No","C:\WINDOWS\cursors\no_im.cur")
                    $RegCursors.SetValue("NWPen","C:\WINDOWS\cursors\pen_im.cur")
                    $RegCursors.SetValue("SizeAll","C:\WINDOWS\cursors\move_im.cur")
                    $RegCursors.SetValue("SizeNESW","C:\WINDOWS\cursors\size1_im.cur")
                    $RegCursors.SetValue("SizeNS","C:\WINDOWS\cursors\size4_im.cur")
                    $RegCursors.SetValue("SizeNWSE","C:\WINDOWS\cursors\size2_im.cur")
                    $RegCursors.SetValue("SizeWE","C:\WINDOWS\cursors\size3_im.cur")
                    $RegCursors.SetValue("UpArrow","C:\WINDOWS\cursors\up_im.cur")
                    $RegCursors.SetValue("Wait","C:\WINDOWS\cursors\busy_im.cur")
                  }
                  7 { # l
                    $RegCursors.SetValue("","l")
                    $RegCursors.SetValue("AppStarting","C:\WINDOWS\cursors\wait_.cur")
                    $RegCursors.SetValue("Arrow","C:\WINDOWS\cursors\arrow_.cur")
                    $RegCursors.SetValue("Crosshair","C:\WINDOWS\cursors\cross_.cur")
                    $RegCursors.SetValue("Hand","")
                    $RegCursors.SetValue("Help","C:\WINDOWS\cursors\help_l.cur")
                    $RegCursors.SetValue("IBeam","C:\WINDOWS\cursors\beam_l.cur")
                    $RegCursors.SetValue("No","C:\WINDOWS\cursors\no_l.cur")
                    $RegCursors.SetValue("NWPen","C:\WINDOWS\cursors\pen_l.cur")
                    $RegCursors.SetValue("SizeAll","C:\WINDOWS\cursors\move_l.cur")
                    $RegCursors.SetValue("SizeNESW","C:\WINDOWS\cursors\size1_l.cur")
                    $RegCursors.SetValue("SizeNS","C:\WINDOWS\cursors\size4_l.cur")
                    $RegCursors.SetValue("SizeNWSE","C:\WINDOWS\cursors\size2_l.cur")
                    $RegCursors.SetValue("SizeWE","C:\WINDOWS\cursors\size3_l.cur")
                    $RegCursors.SetValue("UpArrow","C:\WINDOWS\cursors\up_l.cur")
                    $RegCursors.SetValue("Wait","C:\WINDOWS\cursors\busy_l.cur")
                  }
                  8 { # m
                    $RegCursors.SetValue("","m")
                    $RegCursors.SetValue("AppStarting","C:\WINDOWS\cursors\wait_m.cur")
                    $RegCursors.SetValue("Arrow","C:\WINDOWS\cursors\arrow_m.cur")
                    $RegCursors.SetValue("Crosshair","C:\WINDOWS\cursors\cross_m.cur")
                    $RegCursors.SetValue("Hand","")
                    $RegCursors.SetValue("Help","C:\WINDOWS\cursors\help_m.cur")
                    $RegCursors.SetValue("IBeam","C:\WINDOWS\cursors\beam_m.cur")
                    $RegCursors.SetValue("No","C:\WINDOWS\cursors\no_m.cur")
                    $RegCursors.SetValue("NWPen","C:\WINDOWS\cursors\pen_m.cur")
                    $RegCursors.SetValue("SizeAll","C:\WINDOWS\cursors\move_m.cur")
                    $RegCursors.SetValue("SizeNESW","C:\WINDOWS\cursors\size1_m.cur")
                    $RegCursors.SetValue("SizeNS","C:\WINDOWS\cursors\size4_m.cur")
                    $RegCursors.SetValue("SizeNWSE","C:\WINDOWS\cursors\size2_m.cur")
                    $RegCursors.SetValue("SizeWE","C:\WINDOWS\cursors\size3_m.cur")
                    $RegCursors.SetValue("UpArrow","C:\WINDOWS\cursors\up_m.cur")
                    $RegCursors.SetValue("Wait","C:\WINDOWS\cursors\busy_m.cur")
                  }
                  9 { # r
                    $RegCursors.SetValue("","r")
                    $RegCursors.SetValue("AppStarting","C:\WINDOWS\cursors\wait_r.cur")
                    $RegCursors.SetValue("Arrow","C:\WINDOWS\cursors\arrow_r.cur")
                    $RegCursors.SetValue("Crosshair","C:\WINDOWS\cursors\cross_r.cur")
                    $RegCursors.SetValue("Hand","")
                    $RegCursors.SetValue("Help","C:\WINDOWS\cursors\help_r.cur")
                    $RegCursors.SetValue("IBeam","C:\WINDOWS\cursors\beam_r.cur")
                    $RegCursors.SetValue("No","C:\WINDOWS\cursors\no_r.cur")
                    $RegCursors.SetValue("NWPen","C:\WINDOWS\cursors\pen_r.cur")
                    $RegCursors.SetValue("SizeAll","C:\WINDOWS\cursors\move_r.cur")
                    $RegCursors.SetValue("SizeNESW","C:\WINDOWS\cursors\size1_r.cur")
                    $RegCursors.SetValue("SizeNS","C:\WINDOWS\cursors\size4_r.cur")
                    $RegCursors.SetValue("SizeNWSE","C:\WINDOWS\cursors\size2_r.cur")
                    $RegCursors.SetValue("SizeWE","C:\WINDOWS\cursors\size3_r.cur")
                    $RegCursors.SetValue("UpArrow","C:\WINDOWS\cursors\up_r.cur")
                    $RegCursors.SetValue("Wait","C:\WINDOWS\cursors\busy_r.cur")
                  }
                  10 { #rl
                    $RegCursors.SetValue("","rl")
                    $RegCursors.SetValue("AppStarting","C:\WINDOWS\cursors\wait_rl.cur")
                    $RegCursors.SetValue("Arrow","C:\WINDOWS\cursors\arrow_rl.cur")
                    $RegCursors.SetValue("Crosshair","C:\WINDOWS\cursors\cross_rl.cur")
                    $RegCursors.SetValue("Hand","")
                    $RegCursors.SetValue("Help","C:\WINDOWS\cursors\help_rl.cur")
                    $RegCursors.SetValue("IBeam","C:\WINDOWS\cursors\beam_rl.cur")
                    $RegCursors.SetValue("No","C:\WINDOWS\cursors\no_rl.cur")
                    $RegCursors.SetValue("NWPen","C:\WINDOWS\cursors\pen_rl.cur")
                    $RegCursors.SetValue("SizeAll","C:\WINDOWS\cursors\move_rl.cur")
                    $RegCursors.SetValue("SizeNESW","C:\WINDOWS\cursors\size1_rl.cur")
                    $RegCursors.SetValue("SizeNS","C:\WINDOWS\cursors\size4_rl.cur")
                    $RegCursors.SetValue("SizeNWSE","C:\WINDOWS\cursors\size2_rl.cur")
                    $RegCursors.SetValue("SizeWE","C:\WINDOWS\cursors\size3_rl.cur")
                    $RegCursors.SetValue("UpArrow","C:\WINDOWS\cursors\up_rl.cur")
                    $RegCursors.SetValue("Wait","C:\WINDOWS\cursors\busy_rl.cur")
                  }
                  11 { #rm
                    $RegCursors.SetValue("","rm")
                    $RegCursors.SetValue("AppStarting","C:\WINDOWS\cursors\wait_rm.cur")
                    $RegCursors.SetValue("Arrow","C:\WINDOWS\cursors\arrow_rm.cur")
                    $RegCursors.SetValue("Crosshair","C:\WINDOWS\cursors\cross_rm.cur")
                    $RegCursors.SetValue("Hand","")
                    $RegCursors.SetValue("Help","C:\WINDOWS\cursors\help_rm.cur")
                    $RegCursors.SetValue("IBeam","C:\WINDOWS\cursors\beam_rm.cur")
                    $RegCursors.SetValue("No","C:\WINDOWS\cursors\no_rm.cur")
                    $RegCursors.SetValue("NWPen","C:\WINDOWS\cursors\pen_rm.cur")
                    $RegCursors.SetValue("SizeAll","C:\WINDOWS\cursors\move_rm.cur")
                    $RegCursors.SetValue("SizeNESW","C:\WINDOWS\cursors\size1_rm.cur")
                    $RegCursors.SetValue("SizeNS","C:\WINDOWS\cursors\size4_rm.cur")
                    $RegCursors.SetValue("SizeNWSE","C:\WINDOWS\cursors\size2_rm.cur")
                    $RegCursors.SetValue("SizeWE","C:\WINDOWS\cursors\size3_rm.cur")
                    $RegCursors.SetValue("UpArrow","C:\WINDOWS\cursors\up_rm.cur")
                    $RegCursors.SetValue("Wait","C:\WINDOWS\cursors\busy_rm.cur")
                  }
                  12 { # Kde breeze dark
                    mkdir $HOME\KDE-BREEZE-DARK # Download
                    Write-Output "Downloading from https://github.com/black7375/Breeze-Cursors-for-Windows/"
                    Invoke-webRequest -UseBasicParsing "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/Working.ani" -OutFile "$HOME\KDE-BREEZE-DARK\Working.ani"
                    Invoke-webRequest -UseBasicParsing "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/Working_in_bg.ani" -OutFile "$HOME\KDE-BREEZE-DARK\Working_in_bg.ani"
                    Invoke-webRequest -UseBasicParsing "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/alternate_select.cur" -OutFile "$HOME\KDE-BREEZE-DARK\alternate_select.cur" # UNUSED
                    Invoke-webRequest -UseBasicParsing "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/handwriting.cur" -OutFile "$HOME\KDE-BREEZE-DARK\handwriting.cur"
                    Invoke-webRequest -UseBasicParsing "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/help.cur" -OutFile "$HOME\KDE-BREEZE-DARK\help.cur"
                    Invoke-webRequest -UseBasicParsing "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/link.cur" -OutFile "$HOME\KDE-BREEZE-DARK\link.cur"
                    Invoke-webRequest -UseBasicParsing "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/move.cur" -OutFile "$HOME\KDE-BREEZE-DARK\move.cur"
                    Invoke-webRequest -UseBasicParsing "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/normal_select.cur" -OutFile "$HOME\KDE-BREEZE-DARK\normal_select.cur"
                    Invoke-webRequest -UseBasicParsing "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/precise_select.cur" -OutFile "$HOME\KDE-BREEZE-DARK\precise_select.cur"
                    Invoke-webRequest -UseBasicParsing "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/resize_di_1.cur" -OutFile "$HOME\KDE-BREEZE-DARK\resize_di_1.cur"
                    Invoke-webRequest -UseBasicParsing "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/resize_di_2.cur" -OutFile "$HOME\KDE-BREEZE-DARK\resize_di_2.cur"
                    Invoke-webRequest -UseBasicParsing "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/resize_hor.cur" -OutFile "$HOME\KDE-BREEZE-DARK\resize_hor.cur"
                    Invoke-webRequest -UseBasicParsing "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/resize_ver.cur" -OutFile "$HOME\KDE-BREEZE-DARK\resize_ver.cur"
                    Invoke-webRequest -UseBasicParsing "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/text.cur" -OutFile "$HOME\KDE-BREEZE-DARK\text.cur"
                    Invoke-webRequest -UseBasicParsing "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/unavailable.cur" -OutFile "$HOME\KDE-BREEZE-DARK\unavailable.cur"
                    $RegCursors.SetValue("","KDE Breeze Dark") # Apply
                    $RegCursors.SetValue("AppStarting","$HOME\KDE-BREEZE-DARK\Working_in_bg.ani")
                    $RegCursors.SetValue("Arrow","$HOME\KDE-BREEZE-DARK\normal_select.cur")
                    $RegCursors.SetValue("Crosshair","$HOME\KDE-BREEZE-DARK\precise_select.cur")
                    $RegCursors.SetValue("Hand","$HOME\KDE-BREEZE-DARK\link.cur")
                    $RegCursors.SetValue("Help","$HOME\KDE-BREEZE-DARK\help.cur")
                    $RegCursors.SetValue("IBeam","$HOME\KDE-BREEZE-DARK\text.cur")
                    $RegCursors.SetValue("No","$HOME\KDE-BREEZE-DARK\unavailable.cur")
                    $RegCursors.SetValue("NWPen","$HOME\KDE-BREEZE-DARK\handwriting.cur")
                    $RegCursors.SetValue("SizeAll","$HOME\KDE-BREEZE-DARK\move.cur")
                    $RegCursors.SetValue("SizeNESW","$HOME\KDE-BREEZE-DARK\resize_di_2.cur")
                    $RegCursors.SetValue("SizeNS","$HOME\KDE-BREEZE-DARK\resize_ver.cur")
                    $RegCursors.SetValue("SizeNWSE","$HOME\KDE-BREEZE-DARK\resize_di_1.cur")
                    $RegCursors.SetValue("SizeWE","$HOME\KDE-BREEZE-DARK\resize_hor.cur")
                    $RegCursors.SetValue("UpArrow","$HOME\KDE-BREEZE-DARK\resize_ver.cur")
                    $RegCursors.SetValue("Wait","$HOME\KDE-BREEZE-DARK\Working.ani")
                    # rm -r $HOME\KDE-BREEZE-DARK # Disabled until I test that it's ok to remove them
                  }
                }
                $RegCursors.Close()
                $RegConnect.Close()
                UPDATE_USERPREFERENCESMASK
              } else {
                Write-Output "Canceled"
              }
            }
            5 { # Transparency effects
              $Transparency = $Host.UI.PromptForChoice("Transparency effects:", "", @("&Cancel", "&Enable", "&Disable"), 0)
              switch ($Transparency) {
                0 {
                  Write-Output "`nCanceled"
                }
                1 {
                  Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name 'EnableTransparency' -Value 1
                }
                2 {
                  Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name 'EnableTransparency' -Value 0
                }
              }
            }
            6 { # date and time format
              $op = $Host.UI.PromptForChoice("Date & time display modification:", "", @("&Cancel", "&Formats", "&Taskbar Display"), 0)
              switch ($op) {
                0 { # Cancel
                  Write-Output "Canceled"
                }
                1 { # Formats
                  $GUI = $Host.UI.PromptForChoice("There is a native GUI available for this operation, would you like to use it?", "", @("&GUI", "&CLI"), 0)
                  switch ($GUI) {
                    0 { # GUI
                      intl.cpl
                    }
                    1 { # CLI
                      Write-Output "`nd, dd = day`nddd, dddd = day of the week`nM = month`ny = year`n"
                      $ShortDatePattern = Read-Host "`nShort date (leave blank to skip)"
                      $LongDatePattern = Read-Host "`nLong date (leave blank to skip)"
                      Write-Output "`nh = hour`nm = minute`ns = second (long time only)`ntt = A.M. or P.M.`n`nh/H = 12/24 hour`nhh, mm, ss = display leading zero`nh, m, s = do not display leading zero`n"
                      $ShortTimePattern = Read-Host "`nShort time (leave blank to skip)"
                      $LongTimePattern = Read-Host "`nLong time (leave blank to skip)"
                      if ($ShortDatePattern -match "\S") {
                        Set-ItemProperty -Path "HKCU:\Control Panel\International" -name sShortDate -value "$ShortDatePattern"
                      }
                      if ($LongDatePattern -match "\S") {
                        Set-ItemProperty -Path "HKCU:\Control Panel\International" -name sLongDate -value "$LongDatePattern"
                      }
                      if ($ShortTimePattern -match "\S") {
                        Set-ItemProperty -Path "HKCU:\Control Panel\International" -name sShortTime -value "$ShortTimePattern"
                      }
                      if ($LongTimePattern -match "\S") {
                        Set-ItemProperty -Path "HKCU:\Control Panel\International" -name sTimeFormat -value "$LongTimePattern"
                      }
                      Write-Output "Settings applied, attempting to restart explorer"
                      try {Get-Process explorer | Stop-Process} catch {Write-Output "Explorer restart failed: changes will apply after a restart"}
                    }
                  }
                }
                2 { # Taskbar Display
                  Write-Output "This only works with the new taskbar on versions newer than 22H2."
                  $longTime = $Host.UI.PromptForChoice("Show long time in taskbar?", "", @("&Cancel", "&Show", "&Hide"), 0)
                  switch ($longTime) {
                    0 { # Cancel
                      Write-Output "Canceled"
                    }
                    1 { # Show long time
                      Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -name "ShowSecondsInSystemClock" -value 1
                      try {Get-Process explorer | Stop-Process} catch {Write-Output "Explorer restart failed: changes will apply after a restart"}
                    }
                    2 { # Show short time
                      Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -name "ShowSecondsInSystemClock" -value 0
                      try {Get-Process explorer | Stop-Process} catch {Write-Output "Explorer restart failed: changes will apply after a restart"}
                    }
                  }
                }
              }
            }
            7 { # Animation effects
            Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
[StructLayout(LayoutKind.Sequential)] public struct ANIMATIONINFO {
    public uint cbSize;
    public bool iMinAnimate;
}
public class PInvoke {
    [DllImport("user32.dll")] public static extern bool SystemParametersInfoW(uint uiAction, uint uiParam, ref ANIMATIONINFO pvParam, uint fWinIni);
}
"@
              $animInfo = New-Object ANIMATIONINFO
              $animInfo.cbSize = 8
              $anim = $Host.UI.PromptForChoice("Animation effects:", "", @("&Cancel", "&Enable", "&Disable"), 0)
              switch ($anim) {
                0 { # Cancel
                  Write-Output "Canceled"
                }
                1 { # Enable animation effects
                  $animInfo.iMinAnimate = $true
                  [PInvoke]::SystemParametersInfoW(0x49, 0, [ref]$animInfo, 3)
                }
                2 { # Disable animation effects
                  $animInfo.iMinAnimate = $false
                  [PInvoke]::SystemParametersInfoW(0x49, 0, [ref]$animInfo, 3)
                }
              }
            }
            8 { # Notifications
              $Notifs = $Host.UI.PromptForChoice("Notifications:", "", @("&Cancel", "&Enable", "&Disable", "&Test"), 0)
              switch ($Notifs) {
                0 { # Cancel
                  Write-Output "`nCanceled"
                }
                1 { # Enable
                  try {
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Type "DWord" -Value 1
                  } catch {
                    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Type "DWord" -Value 1
                  }
                  Write-Output "Changes will apply the next time you log in."
                }
                2 { # Disable
                  try {
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Type "DWord" -Value 0
                  } catch {
                    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Type "DWord" -Value 0
                  }
                  Write-Output "Changes will apply the next time you log in."
                }
                3 { # Test
                  Show-Notification "Test notification" "Lorem ipsum dolor sit amet."
                }
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
          Write-output "4. Disable/enable web search in start menu"
          # Prompt user for choice
          $Tbar = Read-Host "`nInput the number of an option from the list above, or leave blank to exit"
          switch ($Tbar) {
            1 { # Move the start menu
              $leftStartMenu = $Host.UI.PromptForChoice("Selecet start menu location preference:", "", @("&Cancel", "&Left", "&Middle"), 0)
              switch ($leftStartMenu) {
                0 {
                  Write-Output "`nCanceled."
                }
                1 {
                  try {
                    Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarAl' -Value 0
                  } catch {
                    New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarAl' -Value 0 -PropertyType Dword
                  }
                  Write-Output "`nLeft start menu applied."
                }
                2 {
                  try {
                    Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarAl' -Value 1
                  } catch {Write-Error ""} # No registry item is same as default
                  Write-Output "`nCenter start menu applied."
                }
              }
            }
            2 { # Move the taskbar
              Write-Output "`nThis does not work on windows 11 version 22H2 or later!`n"
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
                Write-Output "`nTaskbar moved, attempting to restart explorer."
                try {Get-Process explorer | Stop-Process} catch {Write-Output "Explorer restart failed: changes will apply after a restart"}
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
                        Write-Output "`nCanceled"
                      }
                      1 { # task view
                        try {
                          Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'ShowTaskViewButton' -Value 0
                        } catch {
                          New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'ShowTaskViewButton' -Value 0 -PropertyType DWord
                        }
                        Write-Output "`nTask view unpinned"
                      }
                      2 {
                        try {
                          Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'ShowTaskViewButton' -Value 1
                        } catch {Write-Error ""} # No registry item is same as default
                        Write-Output "`nTask view pinned"
                      }
                    }
                  }
                  2 { # Widgets
                    $IPinStatus = $Host.UI.PromptForChoice("Set widget pin status", "", @("&Cancel", "&Unpinned", "&Pinned"), 0)
                    switch ($IPinStatus) {
                      0 {
                        Write-Output "`nCanceled"
                      }
                      1 {
                        try {
                          Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarDa' -Value 0
                        } catch {
                          New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarDa' -Value 0 -PropertyType DWord
                        }
                        Write-Output "`nWidgets unpinned"
                      }
                      2 {
                        try {
                          Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarDa' -Value 1
                        } catch {Write-Error ""} # No registry item is same as default
                        Write-Output "`nWidgets pinned"
                      }
                    }
                  }
                  3 { # Chat
                    $IPinStatus = $Host.UI.PromptForChoice("Set chat pin status", "", @("&Cancel", "&Unpinned", "&Pinned"), 0)
                    switch ($IPinStatus) {
                      0 {
                        Write-Output "`nCanceled"
                      }
                      1 {
                        try {
                          Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarMn' -Value 0
                        } catch {
                          New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarMn' -Value 0 -PropertyType DWord
                        }
                        Write-Output "`nChat unpinned"
                      }
                      2 {
                        try {
                          Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarMn' -Value 1
                        } catch {Write-Error ""} # No registry item is same as default
                        Write-Output "`nChat pinned"
                      }
                    }
                  }
                  4 { # Search
                    $IPinStatus = $Host.UI.PromptForChoice("Set search bar pin status", "", @("&Cancel", "&Unpinned", "&Pinned"), 0)
                    switch ($IPinStatus) {
                      0 {
                        Write-Output "`nCanceled"
                      }
                      1 {
                        try {
                          Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search -Name 'SearchboxTaskbarMode' -Value 0
                        } catch {
                          New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search -Name 'SearchboxTaskbarMode' -Value 0 -PropertyType DWord
                        }
                        Write-Output "`nSearch bar unpinned"
                      }
                      2 {
                        try {
                          Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search -Name 'SearchboxTaskbarMode' -Value 1
                        } catch {Write-Error ""} # No registry item is same as default
                        Write-Output "`nSearch bar pinned"
                      }
                    }
                  }
                }
              } until ($Tpins -notmatch "\S")
            }
            4 { # Web search in start menu
              $searchEnable = $Host.UI.PromptForChoice("Web search in start menu", "", @("&Cancel", "&Disable", "&Enable"), 0)
              switch ($searchEnable) {
                0 { # cancel
                  Write-Output "`nCanceled"
                }
                1 { # disable
                  try {
                    Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search -Name 'BingSearchEnabled' -Value 0
                  } catch {
                    New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search -Name 'BingSearchEnabled' -Value 0 -PropertyType DWord
                  }
                }
                2 { # enable
                  try {
                    Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search -Name 'BingSearchEnabled' -Value 1
                  } catch {
                    Write-Error "" # No action required
                  }
                }
              }
            }
          }
        } until ($Tbar -notmatch "\S")
      }
      3 { # Change input settings
        DO {
          # Print choices
          Write-Output "`n1. Change the keyboard layout"
          Write-Output "2. Change the mouse speed"
          Write-Output "3. Disable sticky keys prompt"
          Write-Output "4. Enable find cursor"
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
                  Write-Output "`nCancled"
                }
                1 {
                  $l[0].InputMethodTips[0]="0409:00000409"
                  Set-WinUserLanguageList -LanguageList $l
                  Write-Output "`nqwerty en-US keyboard layout applied"
                }
                2 {
                  $l[0].InputMethodTips[0]="0409:00010409"
                  Set-WinUserLanguageList -LanguageList $l
                  Write-Output "`nDvorak en-US keyboard layout applied"
                }
              }
            }
            2 { # Mouse speed ( https://renenyffenegger.ch/notes/Windows/PowerShell/examples/WinAPI/modify-mouse-speed )
              DO {
                Write-Output "`n10 is the default mouse speed of windows.`n"
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
                  Write-Output "`nMouse speed set to $MouseSpeed"
                } elseif ($MouseSpeed -notmatch "\S") {
                  Write-Output "`nCanceled"
                } else {
                  Write-Output "`nThat input is out of range or not a number"
                }
              } until ($MouseSpeed -In 1..20 -Or $MouseSpeed -notmatch "\S")
            }
            3 { # Edit sticky keys
              $SKEYS = $Host.UI.PromptForChoice("Sticky keys prompt:", "", @("&Cancel", "&Enable", "&Disable"), 0)
              switch ($SKEYS) {
                0 {
                  Write-Output "`nCanceled"
                }
                1 {
                  [demo.StickyKeys]::EnableHotKey($true, $true)
                }
                2 {
                  [demo.StickyKeys]::EnableHotKey($false, $true)
                }
              }
            }
            4 { # Find Cursor
              Write-Output "I reccomend installing powertoys instead, as it's cursor locate feature looks better"
              $CursorFind = $Host.UI.PromptForChoice("Find cursor", "", @("&Cancel", "&Enable", "&Disable"), 0)
              switch ($CursorFind) {
                0 { # Cancel
                  Write-Output "`nCancled"
                }
                1 { # Enable
                  $Off = $false
                  $Bit = 0x40
                  $B = 1
                  $UserPreferencesMask = (Get-ItemProperty "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask").UserPreferencesMask
                  If ($null -eq $UserPreferencesMask){Write-Error "Cannot find HKCU:\Control Panel\Desktop: UserPreferencesMask"}
                  $NewMask = $UserPreferencesMask
                  if ($Off) {$NewMask[$B] = $NewMask[$B] -band -bnot $Bit} else {$NewMask[$B] = $NewMask[$B] -bor $Bit}
                  if ($NewMask -ne $UserPreferencesMask) {Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value $NewMask}
                  Write-Output "Changes will apply next time you log in"
                }
                2 { # Disable
                  $Off = $true
                  $Bit = 0x40
                  $B = 1
                  $UserPreferencesMask = (Get-ItemProperty "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask").UserPreferencesMask
                  If ($null -eq $UserPreferencesMask){Write-Error "Cannot find HKCU:\Control Panel\Desktop: UserPreferencesMask"}
                  $NewMask = $UserPreferencesMask
                  if ($Off) {$NewMask[$B] = $NewMask[$B] -band -bnot $Bit} else {$NewMask[$B] = $NewMask[$B] -bor $Bit}
                  if ($NewMask -ne $UserPreferencesMask) {Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value $NewMask}
                  Write-Output "Changes will apply next time you log in"
                }
              }
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
          Write-Output "5. Cygwin64"
          Write-Output "6. Clavier+"
          Write-Output "7. eDEX-UI"
          Write-Output "8. GZDoom"
          # Prompt user for input
          $PGram = Read-Host "`nInput the number of an option from the list above, or leave blank to exit"
          switch ($PGram) {
            1 { # FireFox
              $InstallFirefox = $Host.UI.PromptForChoice("Which version of firefox would you like to install?", "", @("&Cancel", "&Latest", "&Nightly", "&Beta", "&Dev", "&ESR"), 0)
              switch ($InstallFirefox) {
                0 { # Cancel
                  Write-Output "`nCanceled"
                }
                1 { # Latest
                  Start-BitsTransfer -source "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US" -destination "$HOME\w11-nau-temp\FireFoxInstall.exe"
                }
                2 { # Nightly
                  Start-BitsTransfer -source "https://download.mozilla.org/?product=firefox-nightly-latest-ssl&os=win64&lang=en-US" -destination "$HOME\w11-nau-temp\FireFoxInstall.exe"
                }
                3 { # Beta
                  Start-BitsTransfer -source "https://download.mozilla.org/?product=firefox-beta-latest-ssl&os=win64&lang=en-US" -destination "$HOME\w11-nau-temp\FireFoxInstall.exe"
                }
                4 { # Dev
                  Start-BitsTransfer -source "https://download.mozilla.org/?product=firefox-devedition-latest-ssl&os=win64&lang=en-US" -destination "$HOME\w11-nau-temp\FireFoxInstall.exe"
                }
                5 { # ESR
                  Start-BitsTransfer -source "https://download.mozilla.org/?product=firefox-esr-latest-ssl&os=win64&lang=en-US" -destination "$HOME\w11-nau-temp\FireFoxInstall.exe"
                }
              }
              if ($InstallFirefox -In 1..5) { # For less repeated code
                Write-Output "`nYou can say `"no`" when it prompts to let the application make changes to your device, and it will still install.`n"
                & $HOME\w11-nau-temp\FireFoxInstall.exe | Out-Null # so that it waits for the installer to complete before going on to the next command
                rm $HOME\w11-nau-temp\FireFoxInstall.exe
              }
            }
            2 { # PowerToys ( https://gist.github.com/laurinneff/b020737779072763628bc30814e67c1a )
              $InstallPowertoys = $Host.UI.PromptForChoice("Install Microsoft PowerToys?", "", @("&Cancel", "&Install"), 0)
              if ($InstallPowertoys -eq 1) {
                $installLocation = "$env:LocalAppData\Programs\PowerToys"
                $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) (New-Guid)
                New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
                Push-Location $tempDir
                $latestPowerToys = Invoke-webRequest -UseBasicParsing "https://api.github.com/repos/microsoft/PowerToys/releases/latest" | ConvertFrom-Json
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
                  Start-BitsTransfer $assetUrl "$assetName" # Start-BitsTransfer instead of Invoke-webRequest here to get a fancy progress bar (also BitsTransfer feels faster, but idk if this is true)
                  $powertoysInstaller = "$tempDir\$assetName"
                  $latestWix = Invoke-webRequest -UseBasicParsing "https://api.github.com/repos/wixtoolset/wix3/releases/latest" | ConvertFrom-Json
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
                  Write-Output "`nFinished installing powertoys!"
                }
              } else {
                Write-Output "`nCanceled"
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
                Write-Output "`nVisual Studio Code installed"
              } else {
                Write-Output "`nCancled"
              }
            }
            4 { # Lapce
              $InstallLapce = $Host.UI.PromptForChoice("Install Lapce?", "", @("&Cancel", "&Install"), 0)
              if ($InstallLapce -eq 1) {
                Write-Output "`nWARNING, THIS PROGRAM MAY NOT WORK WITHOUT MICROSOFT VISUAL STUDIO C++ INSTALLED.`n"
                $latestLapce = Invoke-webRequest -UseBasicParsing "https://api.github.com/repos/lapce/lapce/releases/latest" | ConvertFrom-Json
                $latestVersion = $latestLapce.tag_name.Substring(1)
                Start-BitsTransfer -source "https://github.com/lapce/lapce/releases/download/v$latestVersion/Lapce-windows-portable.zip" -destination "$HOME\w11-nau-temp\Lapce-windows-portable.zip"
                Expand-Archive "$HOME\w11-nau-temp\Lapce-windows-portable.zip" -DestinationPath "$env:LOCALAPPDATA\Lapce" -Force | Out-Null # So it waits to move on to the next one
                Invoke-webRequest -UseBasicParsing "https://www.dropbox.com/scl/fi/3jce5pmrv0yxuu23zvbbc/vcruntime140.dll?rlkey=iktobjfly7orys8we6hjf5l6x&dl=1" -OutFile "$env:LOCALAPPDATA\Lapce\vcruntime140.dll"
                Invoke-webRequest -UseBasicParsing "https://www.dropbox.com/scl/fi/qio77woad985fhf9w9aj4/vcruntime140_1.dll?rlkey=ny0shlgfo2h2xyaikx4g8zcia&dl=1" -OutFile "$env:LOCALAPPDATA\Lapce\vcruntime140_1.dll"
                Invoke-webRequest -UseBasicParsing "https://www.dropbox.com/scl/fi/iws22okw53ft7sjw1axok/msvcp140.dll?rlkey=4mfgeoydrmdtznsmfkaetwecy&dl=1" -OutFile "$env:LOCALAPPDATA\Lapce\msvcp140.dll"
                rm "$HOME\w11-nau-temp\Lapce-windows-portable.zip"
                $WshShell = New-Object -ComObject WScript.Shell
                $Shortcut = $WshShell.CreateShortcut("$env:AppData\Microsoft\Windows\Start Menu\Programs\Lapce.lnk")
                $Shortcut.TargetPath = "$env:LOCALAPPDATA\Lapce\lapce.exe"
                $Shortcut.Save()
                Write-Output "`nLapce installed"
              }
            }
            5 { # Cygwin64
            Write-Output "Licensing information: https://www.cygwin.com/licensing.html"
            $InstallCygwin64 = $Host.UI.PromptForChoice("Install Cygwin64?", "", @("&Cancel", "&Install"), 0)
              if ($InstallCygwin64) {
                Invoke-webRequest -UseBasicParsing "https://www.dropbox.com/scl/fi/6x3exiucwd1rzkrzv5dts/cygwin64.zip?rlkey=5l2p9f48ukez8zdr5gf0jfmxf&dl=1" -OutFile "$HOME\w11-nau-temp\Cygwin64.zip"
                Expand-Archive $HOME\w11-nau-temp\Cygwin64.zip $HOME\Cygwin64.zip | Out-Null
                rm $HOME\w11-nau-temp\Cygwin64.zip
                $WshShell = New-Object -ComObject WScript.Shell
                $Shortcut = $WshShell.CreateShortcut("$env:AppData\Microsoft\Windows\Start Menu\Programs\Cygwin64.lnk")
                $Shortcut.TargetPath = "$HOME\Cygwin64\Cygwin64\bin\mintty.exe"
                $Shortcut.Save()
              }
            }
            6 { # Clavier+
              $InstallClavier = $Host.UI.PromptForChoice("Install Clavier+?", "", @("&Cancel", "&Install"), 0)
              if ($InstallClavier -eq 1) {
                $latestClavier = Invoke-webRequest -UseBasicParsing "https://api.github.com/repos/guilryder/clavier-plus/releases/latest" | ConvertFrom-Json
                $latestVersion = $latestClavier.tag_name.Substring(0)
                Start-BitsTransfer -source "https://github.com/guilryder/clavier-plus/releases/download/$latestVersion/ClavierSetup.exe" -destination "$HOME\w11-nau-temp\ClavierPlus.exe"
                & $HOME\w11-nau-temp\ClavierPlus.exe | Out-Null
                rm $HOME\w11-nau-temp\ClavierPlus.exe
              }
            }
            7 { # eDEX-UI
              $InstallEdex = $Host.UI.PromptForChoice("Install eDEX-UI?", "", @("&Cancel", "&Install"), 0)
              if ($InstallEdex -eq 1) {
                Start-BitsTransfer -source "https://github.com/GitSquared/edex-ui/releases/download/v2.2.8/eDEX-UI-Windows-x64.exe" -destination "$HOME\w11-nau-temp\eDEX-UI.exe"
                & $HOME\w11-nau-temp\eDEX-UI.exe | out-null
                rm $HOME\w11-nau-temp\eDEX-UI.exe
              }
            }
            8 { # GZDoom
              $Install = $Host.UI.PromptForChoice("Install GZDoom?", "", @("&Cancel", "&Install"), 0)
              if ($Install -eq 1) {
                Write-Output "Fetching latest version information..."
                $getLatest = Invoke-webRequest -UseBasicParsing "https://api.github.com/repos/ZDoom/gzdoom/releases/latest" | ConvertFrom-Json
                $latest = $getLatest.tag_name.Substring(1)
                $latestSplit = $getLatest.tag_name.ToString().Split(".")
                $latestMajor = $latestSplit[0].Substring(1)
                $latestMinor = $latestSplit[1]
                $latestMini = $latestSplit[2]
                Write-Output "Downloading latest version..." # Worlds most annoying version name scheme
                Start-BitsTransfer -source "https://github.com/ZDoom/gzdoom/releases/download/g$latest/gzdoom-$latestMajor`-$latestMinor`-$latestMini`-Windows-64bit.zip" -destination "$HOME\w11-nau-temp\GZDoom.zip"
                Start-BitsTransfer -source "https://archive.org/download/2020_03_22_DOOM/DOOM%20WADs/Doom%20%28v1.9%29.zip" -destination "$HOME\w11-nau-temp\doom.zip"
                Start-BitsTransfer -source "https://archive.org/download/2020_03_22_DOOM/DOOM%20WADs/Doom%20II%20-%20Hell%20on%20Earth%20%28v1.9%29.zip" -destination "$HOME\w11-nau-temp\doom2.zip"
                Write-Output "Extracting..."
                Expand-Archive "$HOME\w11-nau-temp\GZDoom.zip" "$HOME\w11-nau-temp\GZDoom" | out-null
                Expand-Archive "$HOME\w11-nau-temp\doom.zip" "$HOME\w11-nau-temp\doom" | out-null
                Expand-Archive "$HOME\w11-nau-temp\doom2.zip" "$HOME\w11-nau-temp\doom2" | out-null
                Write-Output "Installing..."
                mv "$HOME\w11-nau-temp\GZDoom" "$HOME\GZDoom" -force | out-null
                mv "$HOME\w11-nau-temp\doom\DOOM.WAD" "$HOME\GZDoom\DOOM.WAD" -force | out-null
                mv "$HOME\w11-nau-temp\doom2\DOOM2.WAD" "$HOME\GZDoom\DOOM2.WAD" -force | out-null
                Write-Output "Creating shortcut..."
                $WshShell = New-Object -ComObject WScript.Shell
                $Shortcut = $WshShell.CreateShortcut("$env:AppData\Microsoft\Windows\Start Menu\Programs\GZDoom.lnk")
                $Shortcut.TargetPath = "$HOME\GZDoom\gzdoom.exe"
                $Shortcut.Save()
                Write-Output "Cleaning up..."
                rm "$HOME\w11-nau-temp\GZDoom.zip"
                Write-Output "`nDone!"
                Write-Output "`nDownload more Doom WADs from https://archive.org/details/2020_03_22_DOOM`n"
              }
            }
          }
        } until ($PGram -notmatch "\S")
      }
      5 { # Uninstall programs
        Write-Output "" # For consistant formatting
        $PROGRAMS = Get-ChildItem -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall,HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Select-Object -Property DisplayName, UninstallString
        # List installed programs
        $PgListNum = 0
        $PROGRAMS.DisplayName | ForEach-Object {
          if ($_ -match "\S") {
            Write-Output "$PglistNum. $_"
          }
          $PgListNum += 1
        }
        # Ask which program to uninstall
        $UninsNum = Read-Host "`nSelect the number of the program you wish to uninstall, or leave blank to exit"
        if ($UninsNum -match "\S" -and $UninsNum -in 0..($PgListNum-1)) {
          try {
            & $UninstallString
          } catch {
            $UninstallString = $PROGRAMS.UninstallString[$UninsNum]
            # I know you are not supposed to use Invoke-Expression, but there does not seem to be another way
            Invoke-Expression "& $UninstallString"
          }
        } else {
          Write-Output "`nCanceled`n"
        }
      }
      6 { # Command line utilities
        DO {
          # List options
          Write-Output "`n1. Add items to bin"
          Write-Output "2. fastfetch"
          Write-Output "3. ntop"
          Write-Output "4. btop"
          Write-Output "5. gping"
          Write-Output "6. genact"
          Write-Output "7. Text editors"
          Write-Output "8. Qemu"
          # Prompt user for input
          $CLUtils = Read-Host "`nInput the number of an option from the list above, or leave blank to exit"
          switch ($CLUtils) {
            1 { # Add items to bin
              # THIS WHOLE THING NEEDS TO BE REWORDED
              CREATE_BIN
              # Inform user how to exit
              $BinAddItem = Read-Host "`nInput path of item (leave blank to exit)"
              if ($BinAddItem -notmatch "\S") {
                Write-Output "`nCanceled`n"
              } elseif (!(Test-Path $BinAddItem)) {
                Write-Output "`nItem does not exist`n"
              } else {
                $BinOperation = $Host.UI.PromptForChoice("How should the item be put in the bin", "", @("&Cancel", "&Move item", "&Link item"), 0)
                switch ($BinOperation) {
                  0 { # Cancel
                    Write-Output "Canceled"
                  }
                  1 { # Move Item
                    mv $BinAddItem "$HOME\bin"
                  }
                  2 { # Link Item
                    $BinAddName = Read-Host "`nInput command you wish to have call item (leave blank to exit)" # REWORD THIS
                    if ($BinAddName -notmatch "\S") {
                      Write-Output "Canceled"
                    } elseif (Test-Path -Path "$HOME\bin\$BinAddName`.exe" -Or Test-Path -Path "$HOME\bin\$BinAddName`.ps1") {
                      Write-Output "Item with that name already exists in bin"
                    } else {
                      Write-Output "$BinAddItem" > "$HOME\bin\$BinAddName`.ps1"
                    }
                  }
                }
              }
            }
            2 { # Get fastfetch
              $Install = $Host.UI.PromptForChoice("fastfetch:", "", @("&Cancel", "&Install", "&Uninstall"), 0)
              if ($Install -eq 1) {
                CREATE_BIN
                Write-Output "Fetching latest version information..."
                $getLatest = Invoke-webRequest -UseBasicParsing "https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest" | ConvertFrom-Json
                $latest = $getLatest.tag_name.Substring(0)
                Write-Output "Downloading latest version..."
                Start-BitsTransfer -source "https://github.com/fastfetch-cli/fastfetch/releases/download/$latest/fastfetch-$latest`-Win64.zip" -destination "$HOME\w11-nau-temp\fastfetch.zip"
                Write-Output "Extracting..."
                Expand-Archive "$HOME\w11-nau-temp\fastfetch.zip" -DestinationPath "$HOME\w11-nau-temp\fastfetch" -Force
                if (test-path "$HOME\bin\fastfetch.exe") {
                  Write-Output "Removing old version..."
                  rm "$HOME\bin\fastfetch.exe"
                }
                Write-Output "Installing..."
                mv "$HOME\w11-nau-temp\fastfetch\fastfetch.exe" "$HOME\bin" | Out-Null # Just in case
                Write-Output "Cleaning up..."
                rm "$HOME\w11-nau-temp\fastfetch.zip"
                rm "$HOME\w11-nau-temp\fastfetch" -r
                Write-Output "`nDone!"
              } elseif ($Install -eq 2) {
                Write-Output "Uninstalling..."
                rm $HOME\bin\fastfetch.exe
                Write-Output "Done!"
              }
            }
            3 { # Get NTop
              $Install = $Host.UI.PromptForChoice("ntop:", "", @("&Cancel", "&Install", "&Uninstall"), 0)
              if ($Install -eq 1) {
                CREATE_BIN
                Write-Output "Fetching latest version information..."
                $getLatest = Invoke-webRequest -UseBasicParsing "https://api.github.com/repos/gsass1/NTop/releases/latest" | ConvertFrom-Json
                $latest = $getLatest.tag_name.Substring(0)
                if (test-path "$HOME\bin\ntop.exe") {
                  Write-Output "Removing old version..."
                  rm "$HOME\bin\ntop.exe"
                }
                Write-Output "Downloading latest version..."
                Start-BitsTransfer -source "https://github.com/gsass1/NTop/releases/download/$latest/ntop.exe" -destination "$HOME\bin\ntop.exe"
                Write-Output "Installing..."
                Write-Output "Cleaning up..."
                Write-Output "`nDone!"
              } elseif ($Install -eq 2) {
                Write-Output "Uninstalling..."
                rm $HOME\bin\ntop.exe
                Write-Output "Done!"
              }
            }
            4 { # Get btop
              $Install = $Host.UI.PromptForChoice("btop:", "", @("&Cancel", "&Install", "&Uninstall"), 0)
              if ($Install -eq 1) {
                CREATE_BIN
                Write-Output "Fetching latest version information..."
                $getLatest = Invoke-webRequest -UseBasicParsing "https://api.github.com/repos/aristocratos/btop4win/releases/latest" | ConvertFrom-Json
                $latest = $getLatest.tag_name.Substring(0)
                Write-Output "Downloading latest version..."
                Start-BitsTransfer -source "https://github.com/aristocratos/btop4win/releases/download/$latest/btop4win-x64.zip" -destination "$HOME\bin\btop.zip"
                if (test-path "$HOME\bin\btop") {
                  Write-Output "Removing old version..."
                  rm -r "$HOME\bin\btop"
                }
                Write-Output "Extracting..."
                Expand-Archive "$HOME\bin\btop.zip" -DestinationPath "$HOME\bin\btop" -Force
                Write-Output "Installing..."
                Write-Output "$HOME\bin\btop\btop4win\btop4win.exe" > "$HOME\bin\btop.ps1"
                Write-Output "Cleaning up..."
                rm "$HOME\bin\btop.zip"
                Write-Output "`nDone!"
              } elseif ($Install -eq 2) {
                Write-Output "Uninstalling..."
                rm -r $HOME\bin\btop
                rm $HOME\bin\btop.ps1
                Write-Output "Done!"
              }
            }
            5 { # Get gping
              $Install = $Host.UI.PromptForChoice("gping:", "", @("&Cancel", "&Install", "&Uninstall"), 0)
              if ($Install -eq 1) {
                CREATE_BIN
                Write-Output "Fetching latest version information..."
                $getLatest = Invoke-webRequest -UseBasicParsing "https://api.github.com/repos/orf/gping/releases/latest" | ConvertFrom-Json
                $latest = $getLatest.tag_name.Substring(0)
                Write-Output "Downloading latest version..."
                Start-BitsTransfer -source "https://github.com/orf/gping/releases/download/$latest/gping-Windows-x86_64.zip" -destination "$HOME\w11-nau-temp\gping.zip"
                Write-Output "Extracting..."
                Expand-Archive "$HOME\w11-nau-temp\gping.zip" -DestinationPath "$HOME\w11-nau-temp\gping" -Force
                if (test-path "$HOME\bin\gping.exe") {
                  Write-Output "Removing old version..."
                  rm "$HOME\bin\gping.exe"
                }
                Write-Output "Installing..."
                mv "$HOME\w11-nau-temp\gping\gping.exe" "$HOME\bin" | Out-Null # Just in case
                Write-Output "Downloading dependencies..."
                Invoke-webRequest -UseBasicParsing "https://www.dropbox.com/scl/fi/3jce5pmrv0yxuu23zvbbc/vcruntime140.dll?rlkey=iktobjfly7orys8we6hjf5l6x&dl=1" -OutFile "$HOME\bin\vcruntime140.dll"
                Write-Output "Cleaning up..."
                rm "$HOME\w11-nau-temp\gping.zip"
                rm "$HOME\w11-nau-temp\gping" -r
                Write-Output "`nDone!"
              } elseif ($Install -eq 2) {
                Write-Output "Uninstalling..."
                rm $HOME\bin\gping.exe
                Write-Output "Done!"
              }
            }
            6 { # genact
              $Install = $Host.UI.PromptForChoice("genact:", "", @("&Cancel", "&Install", "&Uninstall"), 0)
              if ($Install -eq 1) {
                CREATE_BIN
                Write-Output "Fetching latest version information..."
                $getLatest = Invoke-webRequest -UseBasicParsing "https://api.github.com/repos/svenstaro/genact/releases/latest" | ConvertFrom-Json
                $latest = $getLatest.tag_name.Substring(1)
                if (test-path "$HOME\bin\genact.exe") {
                  Write-Output "Removing old version..."
                  rm "$HOME\bin\genact.exe"
                }
                Write-Output "Downloading latest version..."
                Start-BitsTransfer -source "https://github.com/svenstaro/genact/releases/download/v$latest/genact-$latest`-x86_64-pc-windows-msvc.exe" -destination "$HOME\bin\genact.exe"
                Write-Output "Installing..."
                Write-Output "`nDone!"
              } elseif ($Install -eq 2) {
                Write-Output "Uninstalling..."
                rm $HOME\bin\genact.exe
                Write-Output "Done!"
              }
            }
            7 { # Text editors
              # List choices
              Write-Output "`n1. vim"
              Write-Output "2. neovim"
              Write-Output "3. micro"
              Write-Output "4. nano"
              # Prompt user for input
              $TEdit = Read-Host "`nInput the number of an option from the list above, or leave blank to exit"
              switch ($TEdit) {
                1 { # vim
                  $Install = $Host.UI.PromptForChoice("vim:", "", @("&Cancel", "&Install", "&Uninstall"), 0)
                  if ($Install -eq 1) {
                    CREATE_BIN
                    Write-Output "Fetching latest version information..."
                    $getLatest = Invoke-webRequest -UseBasicParsing "https://api.github.com/repos/vim/vim-win32-installer/releases/latest" | ConvertFrom-Json
                    $latest = $getLatest.tag_name.Substring(1)
                    if (test-path "$HOME\bin\vim.ps1") {
                      Write-Output "Removing old version..."
                      rm -r "$HOME\bin\vim"
                    }
                    Write-Output "Downloading latest version..."
                    Start-BitsTransfer -source "https://github.com/vim/vim-win32-installer/releases/download/v$latest/gvim_$latest`_x64.zip" -destination "$HOME\w11-nau-temp\vim.zip"
                    Write-Output "Extracting..."
                    Expand-Archive $HOME\w11-nau-temp\vim.zip $HOME\w11-nau-temp\vim | out-null
                    Write-Output "Installing..."
                    mv $HOME\w11-nau-temp\vim\vim\vim*\ $HOME\bin\vim | out-null
                    Write-Output "param([Parameter(Position=0)][string[]]`$File); $HOME\bin\vim\vim.exe `$File" > "$HOME\bin\vim.ps1"
                    Write-Output "Cleaning up..."
                    rm -r $HOME\w11-nau-temp\vim
                    rm $HOME\w11-nau-temp\vim.zip
                    Write-Output "`nDone!"
                  } elseif ($Install -eq 2) {
                    Write-Output "Uninstalling..."
                    rm -r $HOME\bin\vim
                    rm $HOME\bin\vim.ps1
                    Write-Output "Done!"
                  }
                }
                2 { # neovim
                  $Install = $Host.UI.PromptForChoice("neovim:", "", @("&Cancel", "&Install", "&Uninstall"), 0)
                  if ($Install -eq 1) {
                    CREATE_BIN
                    if (test-path "$HOME\bin\neovim.ps1") {
                      Write-Output "`nRemoving old version"
                      rm -r "$HOME\bin\nvim"
                    }
                    Write-Output "Downloading latest version..."
                    Start-BitsTransfer -source "https://github.com/neovim/neovim/releases/download/stable/nvim-win64.zip" -destination "$HOME\w11-nau-temp\nvim.zip"
                    Write-Output "Extracting..."
                    Expand-Archive $HOME\w11-nau-temp\nvim.zip $HOME\w11-nau-temp\nvim | out-null
                    Write-Output "Installing..."
                    mv $HOME\w11-nau-temp\nvim\nvim-win64\ $HOME\bin\nvim | out-null
                    Write-Output "param([Parameter(Position=0)][string[]]`$File); $HOME\bin\nvim\bin\nvim.exe `$File" > "$HOME\bin\nvim.ps1"
                    Write-Output "Downloading dependencies..."
                    Invoke-webRequest -UseBasicParsing "https://www.dropbox.com/scl/fi/3jce5pmrv0yxuu23zvbbc/vcruntime140.dll?rlkey=iktobjfly7orys8we6hjf5l6x&dl=1" -OutFile "$HOME\bin\nvim\bin\vcruntime140.dll"
                    Write-Output "Cleaning up..."
                    rm -r $HOME\w11-nau-temp\nvim
                    rm $HOME\w11-nau-temp\nvim.zip
                    Write-Output "`nDone!"
                    Write-Output "`nThe command to run neovim is ``nvim```n"
                  } elseif ($Install -eq 2) {
                    Write-Output "Uninstalling..."
                    rm -r $HOME\bin\nvim
                    rm $HOME\bin\nvim.ps1
                    Write-Output "Done!"
                  }
                }
                3 { # micro
                  $Install = $Host.UI.PromptForChoice("micro:", "", @("&Cancel", "&Install", "&Uninstall"), 0)
                  if ($Install -eq 1) {
                    CREATE_BIN
                    Write-Output "Fetching latest version information..."
                    $getLatest = Invoke-webRequest -UseBasicParsing "https://api.github.com/repos/szyedidia/micro/releases/latest" | ConvertFrom-Json
                    $latest = $getLatest.tag_name.Substring(1)
                    if (test-path "$HOME\bin\micro.exe") {
                      Write-Output "Removing old version..."
                      rm "$HOME\bin\micro.exe"
                    }
                    Write-Output "Downloading latest version..."
                    Start-BitsTransfer -source "https://github.com/zyedidia/micro/releases/download/v$latest/micro-$latest`-win64.zip" -destination "$HOME\w11-nau-temp\micro.zip"
                    Write-Output "Extracting..."
                    Expand-Archive $HOME\w11-nau-temp\micro.zip $HOME\w11-nau-temp\micro | out-null
                    Write-Output "Installing..."
                    mv $HOME\w11-nau-temp\micro\micro*\micro.exe $HOME\bin\micro.exe | out-null
                    Write-Output "Cleaning up..."
                    rm -r $HOME\w11-nau-temp\micro
                    rm $HOME\w11-nau-temp\micro.zip
                    Write-Output "`nDone!"
                  } elseif ($Install -eq 2) {
                    Write-Output "Uninstalling..."
                    rm $HOME\bin\micro.exe
                    Write-Output "Done!"
                  }
                }
                4 { # nano
                  $Install = $Host.UI.PromptForChoice("nano:", "", @("&Cancel", "&Install", "&Uninstall"), 0)
                  if ($Install -eq 1) {
                    CREATE_BIN
                    if (test-path "$HOME\bin\nano.ps1") {
                      Write-Output "Removing old version..."
                      rm -r "$HOME\bin\nano"
                    }
                    Write-Output "Downloading latest version..."
                    Invoke-webRequest -UseBasicParsing "https://www.dropbox.com/scl/fi/9wzwel73vosegmkbg5soa/nano.zip?rlkey=8dwqs4nklqrcb0npq1obm37sx&dl=1" -OutFile $HOME\w11-nau-temp\nano.zip
                    Write-Output "Extracting..."
                    Expand-Archive $HOME\w11-nau-temp\nano.zip $HOME\w11-nau-temp\nano | out-null
                    Write-Output "Installing..."
                    mv $HOME\w11-nau-temp\nano\nano\ $HOME\bin\nano\ | out-null
                    Write-Output "param([Parameter(Position=0)][string[]]`$File); $HOME\bin\nano\bin\nano.exe `$File" > "$HOME\bin\nano.ps1"
                    Write-Output "Cleaning up..."
                    rm -r $HOME\w11-nau-temp\nano
                    rm $HOME\w11-nau-temp\nano.zip
                    Write-Output "`nDone!"
                  } elseif ($Install -eq 2) {
                    Write-Output "Uninstalling..."
                    rm -r $HOME\bin\nano
                    rm $HOME\bin\nano.ps1.ps1
                    Write-Output "Done!"
                  }
                }
              }
            }
            8 { # QEMU
              $Install = $Host.UI.PromptForChoice("QEMU:", "", @("&Cancel", "&Install", "&Uninstall"), 0)
              if ($Install -eq 1) {
                if (test-path "$HOME\qemu") {
                    Write-Output "Removing old version..."
                    rm -r "$HOME\qemu"
                }
                Write-Output "Downloading..."
                Invoke-webRequest -UseBasicParsing "https://www.dropbox.com/scl/fi/qkiat4mvejn15puy4v0fi/qemu.zip?rlkey=qqbihi011pakx2kokbs57z1us&dl=1" -OutFile $HOME\w11-nau-temp\qemu.zip
                Write-Output "Extracting..."
                Expand-Archive $HOME\w11-nau-temp\qemu.zip $HOME\w11-nau-temp\qemu\
                Write-Output "Installing..."
                mv $HOME\w11-nau-temp\qemu\qemu\ $HOME\qemu
                rm $HOME\qemu\launch.ps1 # I didn't want to create a new zip because it's really annoying to.
                Write-Output "Write-Output 'Launching slitaz with 2G ram'; Write-Output 'Root password is root'; $HOME\qemu\qemu-system-x86_64.exe -m 2G -cdrom $HOME\qemu\slitaz-rolling.iso" > $HOME\qemu\slitaz.ps1
                Write-Output "Updating Path..."
                $env:Path += ";$HOME\qemu;"
                if (!(Test-Path -Path $PROFILE.CurrentUserCurrentHost)) {
                  New-Item -ItemType File -Path $PROFILE.CurrentUserCurrentHost -Force
                }
                Write-Output ';$env:Path += ";$HOME\qemu;";' >> $PROFILE.CurrentUserCurrentHost
                Write-Output "Cleaning up..."
                rm $HOME\w11-nau-temp\qemu.zip
                rm -r $HOME\w11-nau-temp\qemu\
                Write-Output "Done!"
                Write-Output "Use command `"slitaz`" to easily launch slitaz linux in qemu"
              } elseif ($Install -eq 2) {
                Write-Output "Uninstalling..."
                rm -r $HOME\qemu
                Write-Output "Done!"
              }
            }
          }
        } until ($CLUtils -notmatch "\S")
      }
    }
  }
} until ($Option -notmatch "\S")
rm -r $HOME\w11-nau-temp
