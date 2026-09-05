# File Structure

The tool has **no external dependencies**. Nothing is downloaded at runtime.

## Essential Files

1. **`Dota2ResolutionSwitcher.ps1`** - the whole tool. Reads and sets the
   display mode through the Win32 API. This is also the source the EXE is
   built from.
2. **`switch_resolution.bat`** - double-click launcher for the script, for
   people who would rather not run a `.ps1` directly.

Either one on its own is enough. Or just grab the prebuilt EXE.

## Optional Files

1. **`SetRefreshRate.ps1`** - list or set the refresh rate at the current
   resolution. Useful after a driver update silently drops you to 60Hz.
2. **`build_exe.ps1`** - rebuilds `dist/Dota2ResolutionSwitcher.exe` via PS2EXE.

## Quick Start for New Users

1. Download the EXE from Releases, **or** clone the repo
2. Double-click the EXE (or `switch_resolution.bat`)

There is no setup step.

---

### Removed in v2.0

`nircmd.exe`, `nircmdc.exe`, `NirCmd.chm`, `setup.bat`, `setup_nircmd.ps1` and
`switch_resolution_nircmd.ps1` are gone. v1.x shelled out to NirCmd to change
the resolution; v2.0 calls the Win32 display API directly, so the download step
and the bundled binaries are no longer needed. They remain in git history.
