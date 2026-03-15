@echo off
:: setup.bat — Steps 2 and 3: Download FXServer.exe and cfx-server-data (Windows)
:: Run this once from the repo root before starting the server with run.bat.
::
:: Requirements:
::   • PowerShell 5+ (built into Windows 10/11; also available on Windows 7/8 via update)
::   • Git for Windows (https://git-scm.com/download/win)

setlocal EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"

:: ── Step 2: Download FiveM server binary ──────────────────────────────────────

echo.
echo === Step 2: Downloading FiveM server binary ===
echo.

if exist "%SCRIPT_DIR%FXServer.exe" (
    echo FXServer.exe already present -- skipping download.
    goto :step3
)

echo Fetching latest Windows artifact version...
powershell -NoProfile -Command ^
    "(Invoke-RestMethod 'https://changelogs-live.fivem.net/api/changelog/versions/win32/server').latest" ^
    > "%TEMP%\fxversion.txt" 2>nul
set /p LATEST= < "%TEMP%\fxversion.txt"
del /q "%TEMP%\fxversion.txt" 2>nul

if "!LATEST!"=="" (
    echo ERROR: Could not fetch the latest FXServer version number.
    echo Please download FXServer.exe manually from:
    echo   https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/
    pause
    exit /b 1
)

set "ZIP_URL=https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/!LATEST!/server.zip"
echo Latest version: !LATEST!
echo Downloading: !ZIP_URL!
echo.

powershell -NoProfile -Command ^
    "Invoke-WebRequest -Uri '!ZIP_URL!' -OutFile '%SCRIPT_DIR%FXServer.zip' -UseBasicParsing"

if not exist "%SCRIPT_DIR%FXServer.zip" (
    echo ERROR: Download failed.
    echo Please download FXServer.exe manually from:
    echo   https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/
    pause
    exit /b 1
)

echo Extracting archive...
powershell -NoProfile -Command ^
    "Expand-Archive -Path '%SCRIPT_DIR%FXServer.zip' -DestinationPath '%SCRIPT_DIR%' -Force"

if not exist "%SCRIPT_DIR%FXServer.exe" (
    echo ERROR: FXServer.exe not found after extraction.
    echo The zip file has been kept at %SCRIPT_DIR%FXServer.zip for troubleshooting.
    echo The archive layout may have changed -- please download manually from:
    echo   https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/
    pause
    exit /b 1
)

del /q "%SCRIPT_DIR%FXServer.zip" 2>nul

echo FXServer.exe downloaded and extracted successfully.

:step3
:: ── Step 3: Clone and merge cfx-server-data ───────────────────────────────────

echo.
echo === Step 3: Downloading default server data (cfx-server-data) ===
echo.

if not exist "%SCRIPT_DIR%cfx-server-data" (
    echo Cloning cfx-server-data...
    git clone https://github.com/citizenfx/cfx-server-data.git "%SCRIPT_DIR%cfx-server-data"
    if !ERRORLEVEL! NEQ 0 (
        echo ERROR: git clone failed.
        echo Make sure Git is installed and available in your PATH.
        echo   https://git-scm.com/download/win
        pause
        exit /b 1
    )
) else (
    echo cfx-server-data already present -- skipping clone.
)

echo.
echo Merging resources into resources\ ...
echo (Only new files are copied -- existing files are not overwritten.)
echo.

:: robocopy exit codes 0-7 are all considered success:
::   0 = no files copied (nothing new), 1 = files copied, 2-7 = extra/mismatched files found
:: Exit codes 8 and above indicate real errors.
robocopy "%SCRIPT_DIR%cfx-server-data\resources" "%SCRIPT_DIR%resources" /E /XC /XN /XO
if !ERRORLEVEL! GEQ 8 (
    echo ERROR: robocopy encountered an error while merging resources.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo  Setup complete!
echo ============================================================
echo.
echo  Next steps:
echo    1. Open server.cfg and uncomment + set sv_licenseKey
echo       (get a free key at https://keymaster.fivem.net)
echo    2. Run run.bat to start the server
echo.
pause
