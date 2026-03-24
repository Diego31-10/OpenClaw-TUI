@echo off
setlocal enabledelayedexpansion
chcp 437 > nul 2>&1
title OpenClaw

reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f > nul 2>&1

for /f "tokens=2" %%W in ('mode con ^| findstr /i "columns"') do set /a "COL=%%W"
for /f "tokens=2" %%H in ('mode con ^| findstr /i "lines"') do set /a "LIN=%%H"
set /a "RATIO=COL*10/LIN"
if !RATIO! LSS 20 (
    mode con: cols=80 lines=28
) else if !RATIO! GEQ 35 (
    mode con: cols=120 lines=38
) else (
    mode con: cols=100 lines=34
)

for /f %%A in ('echo prompt $E ^| cmd') do set "ESC=%%A"
if not defined ESC for /f "delims=" %%A in ('powershell -NoProfile -Command "[char]27"') do set "ESC=%%A"

set "GW_LOG=%TEMP%\openclaw_gw.log"
set "GW_PID_FILE=%TEMP%\openclaw_gw.pid"

<nul set /p "=!ESC![?25l"
set /a "FRAME=0"
call :check_gw

:menu
set /a "FRAME+=1"
if !FRAME! GTR 4 set /a "FRAME=1"
if !FRAME!==1 set "SPIN=|"
if !FRAME!==2 set "SPIN=/"
if !FRAME!==3 set "SPIN=-"
if !FRAME!==4 set "SPIN=\"
if !FRAME!==1 call :check_gw

cls
echo.
echo   !ESC![91m ÛÛÛÛÛÛป ÛÛÛÛÛÛป ÛÛÛÛÛÛÛปÛÛÛป   ÛÛป ÛÛÛÛÛÛปÛÛป      ÛÛÛÛÛป ÛÛป    ÛÛป!ESC![0m
echo   !ESC![91mÛÛษอออÛÛปÛÛษออÛÛปÛÛษออออผÛÛÛÛป  ÛÛบÛÛษออออผÛÛบ     ÛÛษออÛÛปÛÛบ    ÛÛบ!ESC![0m
echo   !ESC![91mÛÛบ   ÛÛบÛÛÛÛÛÛษผÛÛÛÛÛป  ÛÛษÛÛป ÛÛบÛÛบ     ÛÛบ     ÛÛÛÛÛÛÛบÛÛบ Ûป ÛÛบ!ESC![0m
echo   !ESC![91mÛÛบ   ÛÛบÛÛษอออผ ÛÛษออผ  ÛÛบศÛÛปÛÛบÛÛบ     ÛÛบ     ÛÛษออÛÛบÛÛบÛÛÛปÛÛบ!ESC![0m
echo   !ESC![91mศÛÛÛÛÛÛษผÛÛบ     ÛÛÛÛÛÛÛปÛÛบ ศÛÛÛÛบศÛÛÛÛÛÛปÛÛÛÛÛÛÛปÛÛบ  ÛÛบศÛÛÛษÛÛÛษผ!ESC![0m
echo   !ESC![91m ศอออออผ ศอผ     ศออออออผศอผ  ศอออผ ศอออออผศออออออผศอผ  ศอผ ศออผศออผ!ESC![0m
echo.
echo   !ESC![90m ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป!ESC![0m
echo   !ESC![90m บ!ESC![0m  !ESC![91mNODE!ESC![0m !ESC![90m๚!ESC![0m %USERNAME%@%COMPUTERNAME%   !ESC![91mGATEWAY!ESC![0m !ESC![90m๚!ESC![0m !GW_STATUS!   !ESC![91mTIME!ESC![0m !ESC![90m๚!ESC![0m %TIME:~0,8%  !ESC![90mบ!ESC![0m
echo   !ESC![90m ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ!ESC![0m
echo.
echo   !ESC![90m    ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ  ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ!ESC![0m
echo   !ESC![90m    ณ!ESC![0m  !ESC![91m[1]!ESC![0m  !ESC![97mGATEWAY CONTROL!ESC![0m          !ESC![90mณ  ณ!ESC![0m  !ESC![91m[4]!ESC![0m  !ESC![97mWEB DASHBOARD!ESC![0m             !ESC![90mณ!ESC![0m
echo   !ESC![90m    ณ!ESC![0m     !ESC![90mStart ๚ Stop ๚ Restart!ESC![0m   !ESC![90mณ  ณ!ESC![0m     !ESC![90mLocalhost :18789!ESC![0m          !ESC![90mณ!ESC![0m
echo   !ESC![90m    รฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤด  รฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤด!ESC![0m
echo   !ESC![90m    ณ!ESC![0m  !ESC![91m[2]!ESC![0m  !ESC![97mNEURAL MANAGER!ESC![0m           !ESC![90mณ  ณ!ESC![0m  !ESC![91m[5]!ESC![0m  !ESC![97mSUPPORT ^& DOCTOR!ESC![0m         !ESC![90mณ!ESC![0m
echo   !ESC![90m    ณ!ESC![0m     !ESC![90mAuth ๚ Tokens ๚ Status!ESC![0m   !ESC![90mณ  ณ!ESC![0m     !ESC![90mOnboarding ๚ Diagnose!ESC![0m      !ESC![90mณ!ESC![0m
echo   !ESC![90m    รฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤด  รฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤด!ESC![0m
echo   !ESC![90m    ณ!ESC![0m  !ESC![91m[3]!ESC![0m  !ESC![97mSKILLS MODULES!ESC![0m           !ESC![90mณ  ณ!ESC![0m  !ESC![91m[6]!ESC![0m  !ESC![97mEXIT!ESC![0m                      !ESC![90mณ!ESC![0m
echo   !ESC![90m    ณ!ESC![0m     !ESC![90mClawHub ๚ Marketplace!ESC![0m    !ESC![90mณ  ณ!ESC![0m     !ESC![90mClose terminal!ESC![0m            !ESC![90mณ!ESC![0m
echo   !ESC![90m    ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู  ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู!ESC![0m
echo.
echo   !ESC![90m    Press!ESC![0m !ESC![91m1-6!ESC![0m !ESC![90mto navigate  ๚  [!SPIN!]!ESC![0m

choice /c 1234567 /n /t 1 /d 7 > nul 2>&1
set "SEL=!errorlevel!"
if !SEL!==7 goto menu
if !SEL!==6 goto m_exit
if !SEL!==5 goto m_soporte
if !SEL!==4 goto m_web
if !SEL!==3 goto m_skills
if !SEL!==2 goto m_brain
if !SEL!==1 goto m_gateway
goto menu

:: อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
::  [1] GATEWAY CONTROL
:: อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
:m_gateway
call :check_gw
cls
echo.
echo   !ESC![91m ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป!ESC![0m
echo   !ESC![91m บ!ESC![0m  !ESC![97mOpenClaw!ESC![0m !ESC![90m๚!ESC![0m v8  !ESC![90m๚!ESC![0m  !ESC![91mGATEWAY CONTROL!ESC![0m                                !ESC![91mบ!ESC![0m
echo   !ESC![91m ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ!ESC![0m
echo.
echo   !ESC![90m    Status:!ESC![0m  !GW_STATUS!
echo.
echo   !ESC![90m    ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ!ESC![0m
echo   !ESC![90m    ณ!ESC![0m  !ESC![91m[1]!ESC![0m  Start Gateway                  !ESC![90mณ!ESC![0m
echo   !ESC![90m    ณ!ESC![0m  !ESC![91m[2]!ESC![0m  Stop Gateway                   !ESC![90mณ!ESC![0m
echo   !ESC![90m    ณ!ESC![0m  !ESC![91m[3]!ESC![0m  Restart Gateway                !ESC![90mณ!ESC![0m
echo   !ESC![90m    ณ!ESC![0m  !ESC![91m[4]!ESC![0m  View Logs                      !ESC![90mณ!ESC![0m
echo   !ESC![90m    ณ!ESC![0m  !ESC![91m[V]!ESC![0m  Back to Main Menu              !ESC![90mณ!ESC![0m
echo   !ESC![90m    ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู!ESC![0m
echo.
echo   !ESC![91m  ฏ!ESC![0m !ESC![90mSelect:!ESC![0m
<nul set /p "=!ESC![?25l"
choice /c 1234V /n > nul
if errorlevel 5 goto menu
if errorlevel 4 goto gw_logs
if errorlevel 3 goto gw_restart
if errorlevel 2 goto gw_stop
if errorlevel 1 goto gw_start

:gw_start
echo.
echo   !ESC![90m    Starting gateway...!ESC![0m
call :do_gw_start
timeout /t 2 > nul
call :check_gw
echo   !ESC![90m    !GW_STATUS!
echo.
echo   !ESC![90m    Press any key to continue...!ESC![0m
pause > nul
goto m_gateway

:gw_stop
echo.
echo   !ESC![90m    Stopping gateway...!ESC![0m
call :do_gw_stop
echo   !ESC![90m    Done.!ESC![0m
echo.
echo   !ESC![90m    Press any key to continue...!ESC![0m
pause > nul
goto m_gateway

:gw_restart
echo.
echo   !ESC![90m    Restarting gateway...!ESC![0m
call :do_gw_stop
timeout /t 1 > nul
call :do_gw_start
timeout /t 2 > nul
call :check_gw
echo   !GW_STATUS!
echo.
echo   !ESC![90m    Press any key to continue...!ESC![0m
pause > nul
goto m_gateway

:gw_logs
cls
echo.
echo   !ESC![91m ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป!ESC![0m
echo   !ESC![91m บ!ESC![0m  !ESC![97mGATEWAY LOGS!ESC![0m  !ESC![90m๚ last 30 lines ๚!ESC![0m                                !ESC![91mบ!ESC![0m
echo   !ESC![91m ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ!ESC![0m
echo.
if exist "!GW_LOG!" (
    powershell -NoProfile -Command "Get-Content '!GW_LOG!' -Tail 30 -EA SilentlyContinue | %% { '   ' + $_ }"
) else (
    echo   !ESC![90m    No log file found. Start the gateway first.!ESC![0m
)
echo.
echo   !ESC![90m    Press any key to return...!ESC![0m
pause > nul
goto m_gateway

:: อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
::  [2] NEURAL MANAGER
:: อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
:m_brain
cls
echo.
echo   !ESC![91m ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป!ESC![0m
echo   !ESC![91m บ!ESC![0m  !ESC![97mOpenClaw!ESC![0m !ESC![90m๚!ESC![0m v8  !ESC![90m๚!ESC![0m  !ESC![91mNEURAL MANAGER!ESC![0m                             !ESC![91mบ!ESC![0m
echo   !ESC![91m ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ!ESC![0m
echo.
echo   !ESC![90m    ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ!ESC![0m
echo   !ESC![90m    ณ!ESC![0m  !ESC![91m[S]!ESC![0m  Model Status                   !ESC![90mณ!ESC![0m
echo   !ESC![90m    ณ!ESC![0m  !ESC![91m[T]!ESC![0m  Paste Anthropic Token          !ESC![90mณ!ESC![0m
echo   !ESC![90m    ณ!ESC![0m  !ESC![91m[V]!ESC![0m  Back to Main Menu              !ESC![90mณ!ESC![0m
echo   !ESC![90m    ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู!ESC![0m
echo.
echo   !ESC![91m  ฏ!ESC![0m !ESC![90mSelect:!ESC![0m
<nul set /p "=!ESC![?25l"
choice /c STV /n > nul
if errorlevel 3 goto menu
if errorlevel 2 goto brain_token
if errorlevel 1 goto brain_status

:brain_status
echo.
echo   !ESC![90m    --- Querying model status... ---!ESC![0m
echo.
call openclaw models status
echo.
echo   !ESC![90m    Press any key to continue...!ESC![0m
pause > nul
goto menu

:brain_token
echo.
echo   !ESC![91m  ฏ!ESC![0m !ESC![90mPaste your token ^(hidden input^):!ESC![0m
echo.
<nul set /p "=!ESC![?25l!ESC![8m    Token > "
set /p "tok="
<nul set /p "=!ESC![28m"
echo.
if not "!tok!"=="" (
    call openclaw models auth paste-token --provider anthropic !tok!
    echo   !ESC![92m    OK  Token registered.!ESC![0m
) else (
    echo   !ESC![90m    --  Empty token, no changes.!ESC![0m
)
echo.
echo   !ESC![90m    Press any key to continue...!ESC![0m
pause > nul
goto menu

:: อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
::  [3] SKILLS MODULES
:: อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
:m_skills
cls
echo.
echo   !ESC![91m ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป!ESC![0m
echo   !ESC![91m บ!ESC![0m  !ESC![97mOpenClaw!ESC![0m !ESC![90m๚!ESC![0m v8  !ESC![90m๚!ESC![0m  !ESC![91mSKILLS MODULES!ESC![0m                             !ESC![91mบ!ESC![0m
echo   !ESC![91m ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ!ESC![0m
echo.
echo   !ESC![90m    ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ!ESC![0m
echo   !ESC![90m    ณ!ESC![0m  !ESC![91m[B]!ESC![0m  Search skill on ClawHub        !ESC![90mณ!ESC![0m
echo   !ESC![90m    ณ!ESC![0m  !ESC![91m[U]!ESC![0m  Update all skills              !ESC![90mณ!ESC![0m
echo   !ESC![90m    ณ!ESC![0m  !ESC![91m[V]!ESC![0m  Back to Main Menu              !ESC![90mณ!ESC![0m
echo   !ESC![90m    ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู!ESC![0m
echo.
echo   !ESC![91m  ฏ!ESC![0m !ESC![90mSelect:!ESC![0m
<nul set /p "=!ESC![?25l"
choice /c BUV /n > nul
if errorlevel 3 goto menu
if errorlevel 2 goto skills_update
if errorlevel 1 goto skills_search

:skills_update
echo.
echo   !ESC![90m    --- Updating skills... ---!ESC![0m
echo.
call openclaw skills update
echo.
echo   !ESC![90m    Press any key to continue...!ESC![0m
pause > nul
goto menu

:skills_search
echo.
echo   !ESC![91m  ฏ!ESC![0m !ESC![90mSkill name to search:!ESC![0m
echo.
<nul set /p "=    Skill > "
set /p "sk="
echo.
if not "!sk!"=="" (
    call clawdhub search !sk!
) else (
    echo   !ESC![90m    --  Empty search.!ESC![0m
)
echo.
echo   !ESC![90m    Press any key to continue...!ESC![0m
pause > nul
goto menu

:: อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
::  [4] WEB DASHBOARD
:: อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
:m_web
cls
echo.
echo   !ESC![91m ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป!ESC![0m
echo   !ESC![91m บ!ESC![0m  !ESC![97mOpenClaw!ESC![0m !ESC![90m๚!ESC![0m v8  !ESC![90m๚!ESC![0m  !ESC![91mWEB DASHBOARD!ESC![0m                              !ESC![91mบ!ESC![0m
echo   !ESC![91m ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ!ESC![0m
echo.
echo   !ESC![90m    Opening local dashboard in browser...!ESC![0m
echo   !ESC![90m    URL:!ESC![0m !ESC![91mhttp://127.0.0.1:18789/!ESC![0m
echo.
start http://127.0.0.1:18789/
echo   !ESC![92m    OK  Dashboard opened.!ESC![0m
echo.
echo   !ESC![90m    Press any key to return...!ESC![0m
pause > nul
goto menu

:: อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
::  [5] SUPPORT & DOCTOR
:: อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
:m_soporte
cls
echo.
echo   !ESC![91m ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป!ESC![0m
echo   !ESC![91m บ!ESC![0m  !ESC![97mOpenClaw!ESC![0m !ESC![90m๚!ESC![0m v8  !ESC![90m๚!ESC![0m  !ESC![91mSUPPORT ^& DOCTOR!ESC![0m                          !ESC![91mบ!ESC![0m
echo   !ESC![91m ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ!ESC![0m
echo.
echo   !ESC![90m    ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ!ESC![0m
echo   !ESC![90m    ณ!ESC![0m  !ESC![91m[D]!ESC![0m  Doctor -- full diagnostic      !ESC![90mณ!ESC![0m
echo   !ESC![90m    ณ!ESC![0m  !ESC![91m[O]!ESC![0m  Onboarding -- setup wizard     !ESC![90mณ!ESC![0m
echo   !ESC![90m    ณ!ESC![0m  !ESC![91m[V]!ESC![0m  Back to Main Menu              !ESC![90mณ!ESC![0m
echo   !ESC![90m    ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู!ESC![0m
echo.
echo   !ESC![91m  ฏ!ESC![0m !ESC![90mSelect:!ESC![0m
<nul set /p "=!ESC![?25l"
choice /c DOV /n > nul
if errorlevel 3 goto menu
if errorlevel 2 goto sop_onboard
if errorlevel 1 goto sop_doctor

:sop_doctor
echo.
echo   !ESC![90m    --- Running diagnostic... ---!ESC![0m
echo.
call openclaw doctor --non-interactive
echo.
echo   !ESC![90m    Press any key to continue...!ESC![0m
pause > nul
goto menu

:sop_onboard
echo.
call openclaw onboard
goto menu

:: อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
::  [6] EXIT
:: อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
:m_exit
cls
echo.
echo   !ESC![91m    ษออออออออออออออออออออออออออออออออออออออป!ESC![0m
echo   !ESC![91m    บ!ESC![0m  !ESC![97mOpenClaw closed successfully.!ESC![0m       !ESC![91mบ!ESC![0m
echo   !ESC![91m    บ!ESC![0m  !ESC![90mGoodbye, %USERNAME%.!ESC![0m                !ESC![91mบ!ESC![0m
echo   !ESC![91m    ศออออออออออออออออออออออออออออออออออออออผ!ESC![0m
echo.
<nul set /p "=!ESC![?25h"
timeout /t 2 > nul
exit

:: อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
::  SUBROUTINES
:: อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
:check_gw
set "GW_STATUS=!ESC![90m? OFFLINE!ESC![0m"
if exist "!GW_PID_FILE!" (
    set /p "GW_PID=" < "!GW_PID_FILE!"
    tasklist /FI "PID eq !GW_PID!" 2>nul | find "!GW_PID!" > nul 2>&1
    if not errorlevel 1 set "GW_STATUS=!ESC![92m? ONLINE !ESC![0m"
)
exit /b

:do_gw_start
if exist "!GW_PID_FILE!" del "!GW_PID_FILE!" 2>nul
> "%TEMP%\gw_start.ps1" (
    echo $pidf = Join-Path $env:TEMP 'openclaw_gw.pid'
    echo $log  = Join-Path $env:TEMP 'openclaw_gw.log'
    echo $cmd  = "openclaw gateway run ^>^> `"$log`" 2^>^>&1"
    echo $p    = Start-Process cmd -ArgumentList '/c',$cmd -WindowStyle Hidden -PassThru
    echo $p.Id ^| Out-File $pidf -Encoding ASCII -NoNewline
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%TEMP%\gw_start.ps1"
del "%TEMP%\gw_start.ps1" 2>nul
exit /b

:do_gw_stop
if exist "!GW_PID_FILE!" (
    set /p "_PID=" < "!GW_PID_FILE!"
    taskkill /F /T /PID !_PID! > nul 2>&1
    del "!GW_PID_FILE!" 2>nul
)
for /f "tokens=5" %%P in ('netstat -ano 2^>nul ^| find ":18789" ^| find "LISTENING"') do taskkill /F /PID %%P > nul 2>&1
exit /b