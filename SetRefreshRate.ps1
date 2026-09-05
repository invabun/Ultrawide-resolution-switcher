param(
    [int]$Hz = 0,
    [switch]$List
)
# Sets the refresh rate of the primary display at its CURRENT resolution.
#
# Why this is here: a GPU driver update commonly resets both the display scaling
# and the refresh rate to Windows' "recommended" defaults. A monitor that can do
# 165Hz quietly ends up running at 60Hz, which matters far more in a game than
# the resolution does. This checks the mode with CDS_TEST before applying it, so
# an unsupported rate aborts without touching the display.
#
#   .\SetRefreshRate.ps1 -List        show the rates this resolution supports
#   .\SetRefreshRate.ps1 -Hz 165      switch to 165Hz and persist it

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class DispRR {
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

function Get-PrimaryDevice {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $n = [System.Windows.Forms.Screen]::PrimaryScreen.DeviceName
        if ($n) { return $n }
    } catch {}
    return ("{0}{0}.{0}DISPLAY1" -f [char]92)
}
$Device = Get-PrimaryDevice

$cur = [DispRR]::Create()
if (-not [DispRR]::EnumDisplaySettings($Device, $ENUM_CURRENT_SETTINGS, [ref]$cur)) {
    Write-Host "Could not read the current display mode."
    exit 1
}
Write-Host "Current: $($cur.dmPelsWidth)x$($cur.dmPelsHeight) @ $($cur.dmDisplayFrequency)Hz"

$modes = @(); $i = 0
while ($true) {
    $dm = [DispRR]::Create()
    if (-not [DispRR]::EnumDisplaySettings($Device, $i, [ref]$dm)) { break }
    if ($dm.dmPelsWidth -eq $cur.dmPelsWidth -and $dm.dmPelsHeight -eq $cur.dmPelsHeight -and $dm.dmBitsPerPel -eq 32) {
        $modes += $dm
    }
    $i++
}
$rates = $modes | ForEach-Object { $_.dmDisplayFrequency } | Sort-Object -Unique

if ($List -or $Hz -le 0) {
    Write-Host "Available at this resolution: $($rates -join ', ') Hz"
    if ($Hz -le 0 -and -not $List) { Write-Host "Pass -Hz <rate> to apply one." }
    exit 0
}

$pick = $modes | Where-Object { $_.dmDisplayFrequency -eq $Hz } | Select-Object -First 1
if (-not $pick) {
    Write-Host "${Hz}Hz is not offered at this resolution. Available: $($rates -join ', ')"
    exit 1
}

$pick.dmFields = $DM_BITSPERPEL -bor $DM_PELSWIDTH -bor $DM_PELSHEIGHT -bor $DM_DISPLAYFREQUENCY

if ([DispRR]::ChangeDisplaySettings([ref]$pick, $CDS_TEST) -ne 0) {
    Write-Host "The display driver rejected ${Hz}Hz in test. Nothing was changed."
    exit 1
}

$rc = [DispRR]::ChangeDisplaySettings([ref]$pick, $CDS_UPDATEREGISTRY)
if ($rc -ne 0) {
    Write-Host "Failed to apply ${Hz}Hz (code $rc). Nothing was persisted."
    exit 1
}

Start-Sleep -Seconds 2
$new = [DispRR]::Create()
$null = [DispRR]::EnumDisplaySettings($Device, $ENUM_CURRENT_SETTINGS, [ref]$new)
Write-Host "Now:     $($new.dmPelsWidth)x$($new.dmPelsHeight) @ $($new.dmDisplayFrequency)Hz"
exit 0
