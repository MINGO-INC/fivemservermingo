@echo off
:: run.bat — Start the FiveM server on Windows
:: Usage: run.bat [optional-extra-args]

setlocal EnableDelayedExpansion

:: ── Configuration ─────────────────────────────────────────────────────────────
:: Path to the FiveM server binary (FXServer.exe).
:: Default: look in the same directory as this script.
set "SCRIPT_DIR=%~dp0"
set "FXSERVER=%SCRIPT_DIR%FXServer.exe"

if not exist "%FXSERVER%" (
    echo ERROR: FXServer.exe not found at "%FXSERVER%".
    echo   1. Download the server from https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/
    echo   2. Extract FXServer.exe into this directory, OR
    echo   3. Update the FXSERVER variable in this script to point to the correct path.
    pause
    exit /b 1
)

:: ── Launch ─────────────────────────────────────────────────────────────────────
echo Starting FiveM server...
"%FXSERVER%" +exec "%SCRIPT_DIR%server.cfg" %*
