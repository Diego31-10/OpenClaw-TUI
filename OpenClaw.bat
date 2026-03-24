@echo off
setlocal

set "SCRIPT=%~dp0OpenClaw.ps1"
if not exist "%SCRIPT%" (
    echo OpenClaw.ps1 not found in %~dp0
    pause
    exit /b 1
)

powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
set "RC=%ERRORLEVEL%"

if not "%RC%"=="0" (
    echo.
    echo OpenClaw exited with code %RC%.
    pause
)

exit /b %RC%
