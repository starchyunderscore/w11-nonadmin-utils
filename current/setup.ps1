# FUNCTIONS

function CREATE_BIN {
  if (!(Test-Path "$HOME\bin")) {
    Write-Output "`nBin does not exist. Creating."
    mkdir $HOME\bin
    $env:Path += "$HOME\bin"
    if (!(Test-Path -Path $PROFILE.CurrentUserCurrentHost)) {
      New-Item -ItemType File -Path $PROFILE.CurrentUserCurrentHost -Force
    }
    Write-Output ';$env:Path += "$HOME\bin;";' >> $PROFILE.CurrentUserCurrentHost
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

# SCRIPT

Write-Output "`n!!!!!!!!!!`nWARNING: THIS SCRIPT MAKE CHANGES TO THE REGISTRY, MAKE SURE YOU HAVE MADE A RESTORE POINT`n!!!!!!!!!!`n"
$ContinueScript = $Host.UI.PromptForChoice("Are you sure you want to continue?", "", @("&Yes", "&No"), 1)
if ($ContinueScript -eq 1) {
  Write-Output "`nUser quit`n"
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
        Write-Output "3. Change mouse trails length"
        Write-Output "4. Change mouse cursor style"
        Write-Output "5. Transparency effects"
        Write-Output "6. Date and time formats"
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
                Write-Output "`nDark mode applied, restarting explorer."
                Get-Process explorer | Stop-Process
              }
              2 {
                Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 1
                Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Value 1
                Write-Output "`nLight mode applied, restarting explorer."
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

            Write-Output "`nTo get the image path of a file, right click it and select `"Copy as path`""
            Write-Output "`nMake sure your image path is in quotes!`n"
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
              Write-Output "Mouse trail set to $Mtrail, restarting explorer"
              Get-Process explorer | Stop-Process
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
                  mkdir $HOME\KDE-BREEZE-DARK
                  Write-Output "Downloading from https://github.com/black7375/Breeze-Cursors-for-Windows/"
                  Invoke-Webrequest "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/Working.ani" -OutFile "$HOME\KDE-BREEZE-DARK\Working.ani"
                  Invoke-Webrequest "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/Working_in_bg.ani" -OutFile "$HOME\KDE-BREEZE-DARK\Working_in_bg.ani"
                  Invoke-Webrequest "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/alternate_select.cur" -OutFile "$HOME\KDE-BREEZE-DARK\alternate_select.cur" # UNUSED
                  Invoke-Webrequest "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/handwriting.cur" -OutFile "$HOME\KDE-BREEZE-DARK\handwriting.cur"
                  Invoke-Webrequest "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/help.cur" -OutFile "$HOME\KDE-BREEZE-DARK\help.cur"
                  Invoke-Webrequest "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/link.cur" -OutFile "$HOME\KDE-BREEZE-DARK\link.cur"
                  Invoke-Webrequest "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/move.cur" -OutFile "$HOME\KDE-BREEZE-DARK\move.cur"
                  Invoke-Webrequest "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/normal_select.cur" -OutFile "$HOME\KDE-BREEZE-DARK\normal_select.cur"
                  Invoke-Webrequest "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/precise_select.cur" -OutFile "$HOME\KDE-BREEZE-DARK\precise_select.cur"
                  Invoke-Webrequest "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/resize_di_1.cur" -OutFile "$HOME\KDE-BREEZE-DARK\resize_di_1.cur"
                  Invoke-Webrequest "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/resize_di_2.cur" -OutFile "$HOME\KDE-BREEZE-DARK\resize_di_2.cur"
                  Invoke-Webrequest "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/resize_hor.cur" -OutFile "$HOME\KDE-BREEZE-DARK\resize_hor.cur"
                  Invoke-Webrequest "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/resize_ver.cur" -OutFile "$HOME\KDE-BREEZE-DARK\resize_ver.cur"
                  Invoke-Webrequest "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/text.cur" -OutFile "$HOME\KDE-BREEZE-DARK\text.cur"
                  Invoke-Webrequest "https://github.com/black7375/Breeze-Cursors-for-Windows/raw/master/Final/unavailable.cur" -OutFile "$HOME\KDE-BREEZE-DARK\unavailable.cur"

                  $RegCursors.SetValue("","KDE Breeze Dark")
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
            $Transparency = $Host.UI.PromptForChoice("Trancparency effect choice:", "", @("&Cancel", "&Enable", "&Disable"), 0)
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
            
            $op = $Host.UI.PromptForChoice("What part of the time would you like to modify", "", @("&Cancel", "&Formats", "&Taskbar Display"), 0)
            switch (op) {
              0 { # Cancel
                
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
    #                 $FullDateTimePattern = Read-Host "`nFull datetime (leave blank to skip)"
                    if ($ShortDatePattern -match "\S") {
                      Set-ItemProperty -Path "HKCU:\Control Panel\International" -name sShortDate -value "$ShortDatePattern"
    #                   $culture.DateTimeFormat.ShortDatePattern = $ShortDatePattern
                    }
                    if ($LongDatePattern -match "\S") {
                      Set-ItemProperty -Path "HKCU:\Control Panel\International" -name sLongDate -value "$LongDatePattern"
    #                   $culture.DateTimeFormat.LongDatePattern = $LongDatePattern
                    }
                    if ($ShortTimePattern -match "\S") {
                      Set-ItemProperty -Path "HKCU:\Control Panel\International" -name sShortTime -value "$ShortTimePattern"
    #                   $culture.DateTimeFormat.ShortTimePattern = $ShortTimePattern
                    }
                    if ($LongTimePattern -match "\S") {
                      Set-ItemProperty -Path "HKCU:\Control Panel\International" -name sTimeFormat -value "$LongTimePattern"
    #                   $culture.DateTimeFormat.LongTimePattern = $LongTimePattern
                    }
    #                 if ($FullDateTimePattern -match "\S") {
    #                   $culture.DateTimeFormat.FullDateTimePattern = $FullDateTimePattern
    #                 }
    #                 Set-Culture $culture
                    Write-Output "Settings applied - restarting explorer"
                    Get-Process explorer | Stop-Process
                  }
                }
              }
              2 { # Taskbar Display
                $longTime = $Host.UI.PromptForChoice("Show long time in taskbar?", "", @("&Cancel", "&Show", "&Hide"), 0)
                switch ($longTime) {
                  0 { # Cancel
                    Write-Output "Canceled"
                  }
                  1 { # Show long time
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -name "ShowSecondsInSystemClock" -value 1
                  }
                  2 { # Show short time
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -name "ShowSecondsInSystemClock" -value 0
                  }
                }
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
              Write-Output "`nTaskbar moved, restarting explorer."
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
        }
      } until ($Tbar -notmatch "\S")
    }
    3 { # Change input settings
      DO {
        # Print choices
        Write-Output "`n1. Change the keyboard layout"
        Write-Output "2. Change the mouse speed"
        Write-Output "3. Edit sticky keys"
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
            $SKEYS = $Host.UI.PromptForChoice("Enable the sticky keys hotkey?", "", @("&Cancel", "&Enable", "&Disable"), 0)
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
        Write-Output "5. VirtualBox"
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
              Write-Output "`nYou can say `"no`" when it prompts to let the application make changes to your device, and it will still install.`n"
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
              Write-Output "`nWARNING, THIS PROGRAM DOES NOT INSTALL CORRECTLY IN THIS VERSION`n"

              $latestLapce = Invoke-WebRequest "https://api.github.com/repos/lapce/lapce/releases/latest" | ConvertFrom-Json
              $latestVersion = $latestLapce.tag_name.Substring(1)
              Start-BitsTransfer -source "https://github.com/lapce/lapce/releases/download/v$latestVersion/Lapce-windows-portable.zip" -destination ".\Lapce-windows-portable.zip"
              Expand-Archive ".\Lapce-windows-portable.zip" -DestinationPath "$env:LOCALAPPDATA\Lapce" -Force | Out-Null # So it waits to move on to the next one
              rm ".\Lapce-windows-portable.zip"

              $WshShell = New-Object -ComObject WScript.Shell
              $Shortcut = $WshShell.CreateShortcut("$env:AppData\Microsoft\Windows\Start Menu\Programs\Lapce.lnk")
              $Shortcut.TargetPath = "$env:LOCALAPPDATA\Lapce\lapce.exe"
              $Shortcut.Save()
              Write-Output "`nLapce installed"
            }
          }
          5 { # VirtualBox
            Write-Output "NOT DONE YET"
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
                  $BinAddName = Read-Host "`nInput command you wish to have call item" # REWORD THIS
                  if ($BinAddName -notmatch "\S") {
                    Write-Output "Canceled"
                  } elseif (Test-Path -Path "$HOME\bin\$BinAddName`.exe" -Or Test-Path -Path "$HOME\bin\$BinAddName`.ps1" -Or Test-Path -Path "$HOME\bin\$BinAddName`.lnk") {
                    Write-Output "Item with that name already exists in bin"
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

Write-Output "`nScript Finished`n"
Exit 0
