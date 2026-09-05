param(
    [switch]$SetupOnly
)
# Unified one-click script: toggles between 5120x1440 and 2560x1440 silently.
#
# v2 - resolution is read and set through the Win32 display API directly.
# The old version asked System.Windows.Forms for the current resolution and
# shelled out to NirCmd to change it. Screen.Bounds returns DPI-scaled logical
# pixels, so on a machine with display scaling at 125% a real 5120x1440 desktop
# reports as 4096x1152. Neither branch of the toggle matched, every run fell
# through to the 2560x1440 default, and switching back was impossible.
# EnumDisplaySettings reports real pixels regardless of scaling, and it also
# drops the NirCmd dependency entirely.

$WideWidth  = 5120
$WideHeight = 1440
$NarrowWidth  = 2560
$NarrowHeight = 1440

$AppName = "Dota2ResolutionSwitcher"

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Disp {
  [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Ansi)]
  public struct DEVMODE {
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string dmDeviceName;
    public short dmSpecVersion; public short dmDriverVersion; public short dmSize; public short dmDriverExtra;
    public int dmFields;
    public int dmPositionX; public int dmPositionY; public int dmDisplayOrientation; public int dmDisplayFixedOutput;
    public short dmColor; public short dmDuplex; public short dmYResolution; public short dmTTOption; public short dmCollate;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string dmFormName;
    public short dmLogPixels; public int dmBitsPerPel; public int dmPelsWidth; public int dmPelsHeight;
    public int dmDisplayFlags; public int dmDisplayFrequency;
    public int dmICMMethod; public int dmICMIntent; public int dmMediaType; public int dmDitherType;
    public int dmReserved1; public int dmReserved2; public int dmPanningWidth; public int dmPanningHeight;
  }
  public static DEVMODE Create() {
    DEVMODE dm = new DEVMODE();
    dm.dmDeviceName = ""; dm.dmFormName = "";
    dm.dmSize = (short)Marshal.SizeOf(typeof(DEVMODE));
    return dm;
  }
  [DllImport("user32.dll", CharSet=CharSet.Ansi)]
  public static extern bool EnumDisplaySettings(string dev, int mode, ref DEVMODE dm);
  [DllImport("user32.dll", CharSet=CharSet.Ansi)]
  public static extern int ChangeDisplaySettings(ref DEVMODE dm, int flags);
}
"@

$ENUM_CURRENT_SETTINGS = -1
$DM_BITSPERPEL = 0x40000; $DM_PELSWIDTH = 0x80000
$DM_PELSHEIGHT = 0x100000; $DM_DISPLAYFREQUENCY = 0x400000
$CDS_UPDATEREGISTRY = 0x01
$CDS_TEST = 0x02

function Show-Msg($text) {
    try {
        Add-Type -AssemblyName PresentationFramework
        [System.Windows.MessageBox]::Show($text, "Dota2 Resolution Switcher") | Out-Null
    } catch {
        Write-Host $text
    }
}

# EnumDisplaySettings needs an explicit device name; passing $null from
# PowerShell does not marshal through as NULL. Only the NAME is taken from
# Forms here - never Bounds, which is the DPI-scaled value that caused the bug.
function Get-PrimaryDevice {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $n = [System.Windows.Forms.Screen]::PrimaryScreen.DeviceName
        if ($n) { return $n }
    } catch {}
    return ("{0}{0}.{0}DISPLAY1" -f [char]92)
}

$Device = Get-PrimaryDevice

function Get-CurrentMode {
    $dm = [Disp]::Create()
    if (-not [Disp]::EnumDisplaySettings($Device, $ENUM_CURRENT_SETTINGS, [ref]$dm)) {
        throw "Could not read the current display mode."
    }
    return $dm
}

function Get-ModesFor([int]$w, [int]$h) {
    $out = @(); $i = 0
    while ($true) {
        $dm = [Disp]::Create()
        if (-not [Disp]::EnumDisplaySettings($Device, $i, [ref]$dm)) { break }
        if ($dm.dmPelsWidth -eq $w -and $dm.dmPelsHeight -eq $h -and $dm.dmBitsPerPel -eq 32) { $out += $dm }
        $i++
    }
    return $out
}

function Create-DesktopShortcut {
    try {
        $shell = New-Object -ComObject WScript.Shell
        $desktop = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = Join-Path $desktop "Dota2 Resolution Switcher.lnk"

        try {
            $target = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        } catch {
            $target = $null
        }
        # When running as the packaged EXE the shortcut points at the EXE itself.
        # When running as a loose .ps1 the host is powershell.exe, so point the
        # shortcut at PowerShell and pass the script path as an argument.
        if ($target -and $target.ToLower().EndsWith('.exe') -and
            -not $target.ToLower().EndsWith('powershell.exe')) {
            $sc = $shell.CreateShortcut($shortcutPath)
            $sc.TargetPath = $target
            $sc.Arguments = ""
            $sc.WorkingDirectory = Split-Path -Parent $target
            $sc.IconLocation = $target
        } else {
            $sc = $shell.CreateShortcut($shortcutPath)
            $sc.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
            $sc.Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`""
            $sc.WorkingDirectory = Split-Path -Parent $PSCommandPath
            $sc.IconLocation = "$env:SystemRoot\System32\DisplaySwitch.exe,0"
        }
        $sc.Description = "Toggle ${WideWidth}x${WideHeight} <-> ${NarrowWidth}x${NarrowHeight}"
        $sc.Save()
    } catch {}
}

function Switch-Resolution {
    $cur = Get-CurrentMode

    # Anything that is not the wide mode goes wide; the wide mode goes narrow.
    if ($cur.dmPelsWidth -eq $WideWidth -and $cur.dmPelsHeight -eq $WideHeight) {
        $tw = $NarrowWidth; $th = $NarrowHeight
    } else {
        $tw = $WideWidth; $th = $WideHeight
    }

    $modes = Get-ModesFor $tw $th
    if ($modes.Count -eq 0) {
        Show-Msg "Display mode ${tw}x${th} is not available on this monitor.`n`nCurrent: $($cur.dmPelsWidth)x$($cur.dmPelsHeight) @ $($cur.dmDisplayFrequency)Hz"
        return $false
    }

    # Keep the refresh rate the user is already on if the target supports it,
    # otherwise take the highest the target offers.
    $pick = $modes | Where-Object { $_.dmDisplayFrequency -eq $cur.dmDisplayFrequency } | Select-Object -First 1
    if (-not $pick) { $pick = $modes | Sort-Object dmDisplayFrequency -Descending | Select-Object -First 1 }

    $pick.dmFields = $DM_BITSPERPEL -bor $DM_PELSWIDTH -bor $DM_PELSHEIGHT -bor $DM_DISPLAYFREQUENCY

    if ([Disp]::ChangeDisplaySettings([ref]$pick, $CDS_TEST) -ne 0) {
        Show-Msg "The display driver rejected ${tw}x${th} @ $($pick.dmDisplayFrequency)Hz. Nothing was changed."
        return $false
    }

    $rc = [Disp]::ChangeDisplaySettings([ref]$pick, $CDS_UPDATEREGISTRY)
    if ($rc -ne 0) {
        Show-Msg "Failed to change resolution to ${tw}x${th} (code $rc)."
        return $false
    }
    return $true
}

# Main
if ($SetupOnly) {
    Create-DesktopShortcut
    Show-Msg "Setup complete. A desktop shortcut was created (if possible)."
    exit 0
}

# First run on a machine: drop a shortcut on the desktop, once.
$marker = Join-Path $env:LOCALAPPDATA "$AppName\.shortcut-created"
if (-not (Test-Path $marker)) {
    Create-DesktopShortcut
    try {
        $null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $marker) -ErrorAction SilentlyContinue
        Set-Content -Path $marker -Value (Get-Date -Format o) -ErrorAction SilentlyContinue
    } catch {}
}

if (-not (Switch-Resolution)) { exit 1 }
exit 0
