::Run-Engine-Ollama - OpenClaw - Get tokenized dashboard URL.bat

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
::   9. Open dashboard
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

call "%~dp0IsolateEnv-Initialize.bat"

if errorlevel 1 (
    echo.
    echo ERROR: IsolateEnv initialization failed.
    echo.
    pause
    exit /b 1
)

:: ============================================================================
:: OLLAMA CONFIGURATION
:: ============================================================================

set "OLLAMA_HOST=%_HOST%:%_OLLAMA_PORT%"
set "OLLAMA_KEEP_ALIVE=-1"
set "OLLAMA_NUM_PARALLEL=1"
set "OLLAMA_MAX_LOADED_MODELS=1"
set "OLLAMA_MAX_QUEUE=512"

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
:: CHECK OLLAMA SERVER
:: ============================================================================

echo.
echo ============================================================
echo             CHECKING OLLAMA SERVER
echo ============================================================
echo.

curl.exe --silent --show-error --fail ^
    "http://%OLLAMA_HOST%/" >nul 2>&1

if "%ERRORLEVEL%"=="0" (
    echo Ollama is already running on:
    echo   http://%OLLAMA_HOST%
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
    "http://%OLLAMA_HOST%/" >nul 2>&1

if "%ERRORLEVEL%"=="0" goto OLLAMA_READY

set /a OLLAMA_WAIT+=1

if %OLLAMA_WAIT% GEQ 60 (
    echo.
    echo ERROR: Ollama did not become ready within 60 seconds.
    echo.
    echo Expected:
    echo   http://%OLLAMA_HOST%
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
:: VERIFY OLLAMA API BEFORE OPENCLAW
:: ============================================================================

echo.
echo ============================================================
echo             VERIFYING OLLAMA API
echo ============================================================
echo.

curl.exe --silent --show-error --fail ^
    "http://%OLLAMA_HOST%/api/tags" >nul 2>&1

if not "%ERRORLEVEL%"=="0" (
    echo.
    echo ERROR: Ollama API is not responding.
    echo.
    echo Expected:
    echo   http://%OLLAMA_HOST%/api/tags
    echo.
    pause
    exit /b 1
)

echo Ollama API is responding.
echo.

:: ============================================================================
:: START OPENCLAW GATEWAY
:: ============================================================================
::
:: The Gateway MUST run from this isolated process environment.
:: Do not reuse a separately installed Windows Gateway process.
::
:: ============================================================================

echo.
echo ============================================================
echo             STARTING OPENCLAW GATEWAY
echo ============================================================
echo.

call "%OPENCLAW_CMD%" gateway stop >nul 2>&1

timeout /t 1 /nobreak >nul

echo Starting OpenClaw Gateway...
echo.

start "OpenClaw Gateway" /min cmd /c ^
    ""%OPENCLAW_CMD%" gateway --port 18789"

:: ============================================================================
:: WAIT FOR OPENCLAW GATEWAY
:: ============================================================================

echo Waiting for OpenClaw Gateway...

set /a OPENCLAW_WAIT=0

:WAIT_OPENCLAW

curl.exe --silent --show-error --fail ^
    "http://%_HOST%:18789/" >nul 2>&1

if "%ERRORLEVEL%"=="0" goto OPENCLAW_READY

set /a OPENCLAW_WAIT+=1

if %OPENCLAW_WAIT% GEQ 90 (
    echo.
    echo ERROR: OpenClaw Gateway did not become ready within 90 seconds.
    echo.
    echo Expected:
    echo   http://%_HOST%:18789
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
:: OPEN DASHBOARD
:: ============================================================================

echo.
echo ============================================================
echo              OPENING OPENCLAW DASHBOARD
echo ============================================================
echo.

call "%OPENCLAW_CMD%" dashboard

set "OPENCLAW_EXIT=%ERRORLEVEL%"

if not "%OPENCLAW_EXIT%"=="0" (
    echo.
    echo ERROR: OpenClaw dashboard command failed.
    echo.
    pause
    exit /b %OPENCLAW_EXIT%
)

echo.
echo ============================================================
echo       PORTABLE OLLAMA + OPENCLAW IS RUNNING
echo ============================================================
echo.
echo Ollama:
echo   http://%OLLAMA_HOST%
echo.
echo OpenClaw:
echo   http://%_HOST%:18789
echo.
echo Ollama and OpenClaw Gateway remain running.
echo.
echo ============================================================
echo.

endlocal
exit /b 0