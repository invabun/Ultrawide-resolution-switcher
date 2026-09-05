@echo off
REM Resolution Switch - Toggles between 2560x1440 and 5120x1440
REM No external tools required. Window closes automatically after switching.

powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0Dota2ResolutionSwitcher.ps1"
exit /b %errorLevel%
