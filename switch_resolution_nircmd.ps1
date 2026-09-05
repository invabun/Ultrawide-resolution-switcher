# Resolution Switch Script
#
# Kept under its original name so existing shortcuts and switch_resolution.bat
# keep working. NirCmd is NO LONGER REQUIRED - all the work now happens in
# Dota2ResolutionSwitcher.ps1, which talks to the Win32 display API directly.
#
# The logic that used to live here read the current resolution via
# System.Windows.Forms Screen.Bounds, which returns DPI-scaled logical pixels.
# With display scaling at 125% a real 5120x1440 desktop reported as 4096x1152,
# so neither toggle branch matched and every run targeted 2560x1440 - meaning
# switching back to the wide mode silently did nothing.

$main = Join-Path $PSScriptRoot "Dota2ResolutionSwitcher.ps1"

if (-not (Test-Path $main)) {
    Write-Host "Dota2ResolutionSwitcher.ps1 not found next to this script."
    Start-Sleep -Seconds 3
    exit 1
}

& $main
exit $LASTEXITCODE
