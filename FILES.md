# File Structure

## Essential Files

As of v2.0 the tool has **no external dependencies**. NirCmd is not used.

1. **`Dota2ResolutionSwitcher.ps1`** - the whole tool. Reads and sets the
   display mode through the Win32 API. This is also the source the EXE is
   built from.
2. **`switch_resolution.bat`** - double-click launcher for the script, for
   people who would rather not run a `.ps1` directly.

That is the complete set. Either one on its own is enough.

## Optional Files

1. **`SetRefreshRate.ps1`** - list or set the refresh rate at the current
   resolution. Useful after a driver update silently drops you to 60Hz.
2. **`build_exe.ps1`** - rebuilds `dist/Dota2ResolutionSwitcher.exe` via PS2EXE.
3. **`README.md`** - documentation.

## Legacy Files

Kept so existing shortcuts do not break, but no longer required:

- **`switch_resolution_nircmd.ps1`** - now a thin wrapper that just calls
  `Dota2ResolutionSwitcher.ps1`. The name is historical.
- **`setup.bat`** / **`setup_nircmd.ps1`** - downloaded NirCmd. Nothing needs
  NirCmd any more, so setup is no longer a step.
- **`nircmd.exe`** / **`nircmdc.exe`** / **`NirCmd.chm`** - unused.

## Quick Start for New Users

1. Download the EXE from Releases, **or** clone the repo
2. Double-click the EXE (or `switch_resolution.bat`)

There is no setup step any more.
