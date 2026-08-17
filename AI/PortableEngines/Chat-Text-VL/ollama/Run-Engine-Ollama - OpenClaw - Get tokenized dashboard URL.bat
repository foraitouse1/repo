@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ============================================================================
:: Run-Engine-Ollama - OpenClaw - Get tokenized dashboard URL.bat
:: ============================================================================
::
:: PURPOSE
::
::   Start the isolated Ollama + OpenClaw environment.
::
::   1. Load IsolateEnv.bat
::   2. Load IsolateEnv-Project.bat
::   3. Add isolated Ollama / Node / OpenClaw to PATH
::   4. Run "ollama signin"
::   5. Start portable Ollama
::   6. Wait for Ollama
::   7. Start OpenClaw Gateway
::   8. Wait for OpenClaw
::   9. Get tokenized dashboard URL
::  10. Save OPENCLAW_DASHBOARD_URL to IsolateEnv-Project.bat
::  11. Open dashboard
::
:: IMPORTANT
::
::   SCRIPT_DIR is intentionally determined from THIS SCRIPT.
::   Therefore the same environment can be copied to a different location
::   on the host without hard-coded SCRIPT_DIR paths.
::
:: ============================================================================

title Portable Ollama + OpenClaw

echo.
echo ============================================================
echo        STARTING PORTABLE OLLAMA + OPENCLAW
echo ============================================================
echo.

:: ============================================================================
:: SCRIPT LOCATION
:: ============================================================================

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: ============================================================================
:: LOAD ISOLATED WINDOWS ENVIRONMENT
:: ============================================================================

if not exist "%SCRIPT_DIR%\IsolateEnv.bat" (
    echo.
    echo ERROR: IsolateEnv.bat not found:
    echo %SCRIPT_DIR%\IsolateEnv.bat
    echo.
    pause
    exit /b 1
)

call "%SCRIPT_DIR%\IsolateEnv.bat"

if errorlevel 1 (
    echo.
    echo ERROR: IsolateEnv.bat failed.
    echo.
    pause
    exit /b 1
)

:: ============================================================================
:: LOAD PROJECT-SPECIFIC ENVIRONMENT
:: ============================================================================

if exist "%SCRIPT_DIR%\IsolateEnv-Project.bat" (
    call "%SCRIPT_DIR%\IsolateEnv-Project.bat"

    if errorlevel 1 (
        echo.
        echo ERROR: IsolateEnv-Project.bat failed.
        echo.
        pause
        exit /b 1
    )
)

:: ============================================================================
:: ENSURE SCRIPT DIRECTORY IS CORRECT
:: ============================================================================

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: ============================================================================
:: ISOLATED APPLICATION LOCATIONS
:: ============================================================================

set "_ENGINE_DIR=%SCRIPT_DIR%\Ollama"
set "_NODEJS_DIR=%SCRIPT_DIR%\Nodejs"
set "_OPENCLAW_DIR=%SCRIPT_DIR%\Nodejs"

set "OLLAMA_MODELS=%SCRIPT_DIR%\Models"

:: ============================================================================
:: OLLAMA CONFIGURATION
:: ============================================================================

if not defined _OLLAMA_PORT set "_OLLAMA_PORT=11434"

set "OLLAMA_HOST=127.0.0.1:%_OLLAMA_PORT%"
set "OLLAMA_KEEP_ALIVE=-1"
set "OLLAMA_NUM_PARALLEL=1"
set "OLLAMA_MAX_LOADED_MODELS=1"
set "OLLAMA_MAX_QUEUE=512"

:: ============================================================================
:: OPENCLAW CONFIGURATION
:: ============================================================================

set "OPENCLAW_GATEWAY_PORT=18789"
set "OPENCLAW_GATEWAY_HOST=127.0.0.1"

:: ============================================================================
:: PATH
:: ============================================================================

set "PATH=%_ENGINE_DIR%;%_NODEJS_DIR%;%_NODEJS_DIR%\Scripts;%PATH%"

:: OpenClaw npm global command locations
if exist "%_NODEJS_DIR%\openclaw.cmd" (
    set "OPENCLAW_CMD=%_NODEJS_DIR%\openclaw.cmd"
) else (
    if exist "%_NODEJS_DIR%\openclaw" (
        set "OPENCLAW_CMD=%_NODEJS_DIR%\openclaw"
    ) else (
        echo.
        echo ERROR: OpenClaw command was not found.
        echo.
        echo Checked:
        echo   %_NODEJS_DIR%\openclaw.cmd
        echo   %_NODEJS_DIR%\openclaw
        echo.
        pause
        exit /b 1
    )
)

set "OLLAMA_EXE=%_ENGINE_DIR%\ollama.exe"

:: ============================================================================
:: DISPLAY ENVIRONMENT
:: ============================================================================

echo.
echo ============================================================
echo       ISOLATED ENVIRONMENT
echo ============================================================
echo.
echo SCRIPT_DIR:        %SCRIPT_DIR%
echo Ollama:            %OLLAMA_EXE%
echo Ollama Models:     %OLLAMA_MODELS%
echo Ollama Host:       %OLLAMA_HOST%
echo OpenClaw:          %OPENCLAW_CMD%
echo OpenClaw Gateway:  %OPENCLAW_GATEWAY_HOST%:%OPENCLAW_GATEWAY_PORT%
echo.

:: ============================================================================
:: VERIFY OLLAMA EXECUTABLE
:: ============================================================================

if not exist "%OLLAMA_EXE%" (
    echo ERROR: Ollama executable not found:
    echo %OLLAMA_EXE%
    echo.
    pause
    exit /b 1
)

:: ============================================================================
:: OLLAMA SIGN-IN
:: ============================================================================
::
:: This is intentionally interactive.
::
:: The sign-in state is created under the isolated USERPROFILE/HOME established
:: by IsolateEnv.bat rather than the host user's normal environment.
::
:: ============================================================================

echo.
echo ============================================================
echo              OLLAMA SIGN-IN
echo ============================================================
echo.
echo Running:
echo.
echo   ollama signin
echo.
echo Complete the Ollama sign-in if prompted.
echo.

"%OLLAMA_EXE%" signin

set "SIGNIN_ERROR=%ERRORLEVEL%"

if not "%SIGNIN_ERROR%"=="0" (
    echo.
    echo WARNING: ollama signin returned exit code %SIGNIN_ERROR%.
    echo.
    echo The script will continue so that an existing sign-in can still
    echo be used by Ollama/OpenClaw.
    echo.
)

:: ============================================================================
:: STOP ANY OLD PORTABLE OLLAMA SERVER USING THIS PORT
:: ============================================================================
::
:: Do NOT kill arbitrary ollama.exe processes.
::
:: We only check whether our configured port is already responding.
::
:: ============================================================================

echo.
echo ============================================================
echo             CHECKING OLLAMA SERVER
echo ============================================================
echo.

curl.exe --silent --show-error --fail ^
    "http://127.0.0.1:%_OLLAMA_PORT%/" >nul 2>&1

if "%ERRORLEVEL%"=="0" (
    echo Ollama is already running on:
    echo   http://127.0.0.1:%_OLLAMA_PORT%
    echo.
    goto OLLAMA_READY
)

:: ============================================================================
:: START PORTABLE OLLAMA
:: ============================================================================

echo Starting portable Ollama...
echo.
echo Executable:
echo   %OLLAMA_EXE%
echo.
echo Host:
echo   %OLLAMA_HOST%
echo.
echo Models:
echo   %OLLAMA_MODELS%
echo.

start "Portable Ollama" /min cmd /c ^
    ""%OLLAMA_EXE%" serve"

:: ============================================================================
:: WAIT FOR OLLAMA
:: ============================================================================

echo Waiting for Ollama...

set /a OLLAMA_WAIT=0

:WAIT_OLLAMA

curl.exe --silent --show-error --fail ^
    "http://127.0.0.1:%_OLLAMA_PORT%/" >nul 2>&1

if "%ERRORLEVEL%"=="0" goto OLLAMA_READY

set /a OLLAMA_WAIT+=1

if %OLLAMA_WAIT% GEQ 60 (
    echo.
    echo ERROR: Ollama did not become ready within 60 seconds.
    echo.
    echo Expected:
    echo   http://127.0.0.1:%_OLLAMA_PORT%
    echo.
    pause
    exit /b 1
)

timeout /t 1 /nobreak >nul
goto WAIT_OLLAMA

:: ============================================================================
:: OLLAMA READY
:: ============================================================================

:OLLAMA_READY

echo.
echo Ollama is ready.
echo.

:: ============================================================================
:: START OPENCLAW GATEWAY
:: ============================================================================
::
:: OpenClaw's Control UI is served by the Gateway.
:: Current OpenClaw documentation uses port 18789 by default.
::
:: ============================================================================

echo.
echo ============================================================
echo             STARTING OPENCLAW GATEWAY
echo ============================================================
echo.

:: Check whether the Gateway is already responding.

curl.exe --silent --show-error --fail ^
    "http://127.0.0.1:%OPENCLAW_GATEWAY_PORT%/" >nul 2>&1

if "%ERRORLEVEL%"=="0" (
    echo OpenClaw Gateway is already running.
    goto OPENCLAW_READY
)

echo Starting OpenClaw Gateway...
echo.

start "OpenClaw Gateway" /min cmd /c ^
    ""%OPENCLAW_CMD%" gateway --port %OPENCLAW_GATEWAY_PORT%"

:: ============================================================================
:: WAIT FOR OPENCLAW GATEWAY
:: ============================================================================

echo Waiting for OpenClaw Gateway...

set /a OPENCLAW_WAIT=0

:WAIT_OPENCLAW

curl.exe --silent --show-error --fail ^
    "http://127.0.0.1:%OPENCLAW_GATEWAY_PORT%/" >nul 2>&1

if "%ERRORLEVEL%"=="0" goto OPENCLAW_READY

set /a OPENCLAW_WAIT+=1

if %OPENCLAW_WAIT% GEQ 90 (
    echo.
    echo ERROR: OpenClaw Gateway did not become ready within 90 seconds.
    echo.
    echo Expected:
    echo   http://127.0.0.1:%OPENCLAW_GATEWAY_PORT%
    echo.
    echo Check the OpenClaw Gateway window for errors.
    echo.
    pause
    exit /b 1
)

timeout /t 1 /nobreak >nul
goto WAIT_OPENCLAW

:: ============================================================================
:: OPENCLAW READY
:: ============================================================================

:OPENCLAW_READY

echo.
echo OpenClaw Gateway is ready.
echo.

:: ============================================================================
:: GET TOKENIZED DASHBOARD URL
:: ============================================================================
::
:: OpenClaw officially supports:
::
::   openclaw dashboard --json
::
:: The JSON result contains:
::
::   url
::   httpUrl
::   wsUrl
::   port
::   tokenIncluded
::
:: ============================================================================

echo.
echo ============================================================
echo          GETTING TOKENIZED DASHBOARD URL
echo ============================================================
echo.

set "DASHBOARD_JSON=%TEMP%\OpenClawDashboard_%RANDOM%.json"

"%OPENCLAW_CMD%" dashboard --json > "%DASHBOARD_JSON%" 2>&1

set "DASHBOARD_ERROR=%ERRORLEVEL%"

if not "%DASHBOARD_ERROR%"=="0" (
    echo.
    echo ERROR: OpenClaw could not produce the dashboard URL.
    echo.
    echo OpenClaw output:
    echo ------------------------------------------------------------
    type "%DASHBOARD_JSON%"
    echo ------------------------------------------------------------
    echo.
    del /q "%DASHBOARD_JSON%" >nul 2>&1
    pause
    exit /b 1
)

:: ============================================================================
:: EXTRACT URL USING POWERSHELL
:: ============================================================================

set "DASHBOARD_URL="

for /f "usebackq delims=" %%U in (`powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "$j = Get-Content -Raw -LiteralPath '%DASHBOARD_JSON%' ^| ConvertFrom-Json; if ($j.url) { $j.url }"`) do (
    set "DASHBOARD_URL=%%U"
)

:: ============================================================================
:: CLEAN UP JSON
:: ============================================================================

del /q "%DASHBOARD_JSON%" >nul 2>&1

:: ============================================================================
:: VERIFY URL
:: ============================================================================

if not defined DASHBOARD_URL (
    echo.
    echo ERROR: OpenClaw returned no dashboard URL.
    echo.
    echo Run manually:
    echo   %OPENCLAW_CMD% dashboard --json
    echo.
    pause
    exit /b 1
)

:: ============================================================================
:: DISPLAY URL
:: ============================================================================

echo.
echo ============================================================
echo             OPENCLAW DASHBOARD URL
echo ============================================================
echo.
echo %DASHBOARD_URL%
echo.

:: ============================================================================
:: SAVE URL TO IsolateEnv-Project.bat
:: ============================================================================
::
:: IMPORTANT:
::
:: IsolateEnv-Project-Add.bat compares ONLY the actual SET variable/value.
:: Comments are NOT part of the duplicate/value test.
::
:: ============================================================================

if not exist "%SCRIPT_DIR%\IsolateEnv-Project-Add.bat" (
    echo.
    echo ERROR: IsolateEnv-Project-Add.bat not found:
    echo %SCRIPT_DIR%\IsolateEnv-Project-Add.bat
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo       SAVING DASHBOARD URL TO PROJECT ENVIRONMENT
echo ============================================================
echo.

call "%SCRIPT_DIR%\IsolateEnv-Project-Add.bat" ^
    "%~n0%~x0" ^
    SET "OPENCLAW_DASHBOARD_URL=%DASHBOARD_URL%"

if errorlevel 1 (
    echo.
    echo ERROR: Could not save OPENCLAW_DASHBOARD_URL.
    echo.
    pause
    exit /b 1
)

echo.
echo OPENCLAW_DASHBOARD_URL saved to:
echo   %SCRIPT_DIR%\IsolateEnv-Project.bat
echo.

:: ============================================================================
:: OPEN DASHBOARD
:: ============================================================================

echo.
echo ============================================================
echo              OPENING OPENCLAW DASHBOARD
echo ============================================================
echo.

start "" "%DASHBOARD_URL%"

echo.
echo ============================================================
echo       PORTABLE OLLAMA + OPENCLAW IS RUNNING
echo ============================================================
echo.
echo Ollama:
echo   http://127.0.0.1:%_OLLAMA_PORT%
echo.
echo OpenClaw:
echo   http://127.0.0.1:%OPENCLAW_GATEWAY_PORT%
echo.
echo Tokenized Dashboard:
echo   %DASHBOARD_URL%
echo.
echo Dashboard URL has been saved to:
echo   %SCRIPT_DIR%\IsolateEnv-Project.bat
echo.
echo Ollama and OpenClaw Gateway remain running.
echo.
echo ============================================================
echo.

endlocal
exit /b 0
