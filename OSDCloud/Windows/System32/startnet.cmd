@echo off
wpeinit

REM Wait for system to fully initialize
timeout /t 10 /nobreak >nul

echo.
echo ============================================
echo    Windows Autopilot HWID Collection
echo ============================================
echo.

REM Check if we're on a removable drive (USB)
for %%i in (D: E: F: G: H: I: J: K: L: M: N: O: P: Q: R: S: T: U: V: W: X: Y: Z:) do (
    if exist "%%i\AutoExportHWID_WinPE_Fixed.ps1" (
        echo Found script on %%i
        %%i
        cd \
        goto :runscript
    )
)

REM If not found on removable drives, try current directory
if exist "AutoExportHWID_WinPE_Fixed.ps1" goto :runscript

echo ERROR: AutoExportHWID_WinPE_Fixed.ps1 not found!
echo Please ensure the script is in the same folder as startnet.cmd
pause
exit /b 1

:runscript
echo Starting PowerShell script...
echo.
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "AutoExportHWID_WinPE_Fixed.ps1"

echo.
echo ============================================
echo Script execution completed
echo ============================================
echo.
echo Files should be saved in the current directory
dir /b *.csv 2>nul
echo.
pause