:: Run-Engine-Ollama - OpenClaw - Get tokenized dashboard URL.bat

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
::   1. Load IsolateEnv-Initialize.bat
::   2. Configure isolated Ollama environment
::   3. Add isolated Ollama / Node / OpenClaw to PATH
::   4. Verify Ollama executable
::   5. Start portable Ollama if it is not already running
::   6. Wait for Ollama
::   7. Verify Ollama API
::   8. Start OpenClaw Gateway in the isolated environment
::   9. Wait for OpenClaw Gateway
::  10. Open the OpenClaw dashboard
::
:: IMPORTANT
::
::   - NO "ollama signin"
::   - NO Ollama cloud authentication is performed here.
::   - NO OpenClaw Gateway service is installed or started.
::   - The Gateway is launched directly from this isolated environment.
::   - The onboarding script configures OpenClaw.
::   - THIS script runs OpenClaw.
::
:: ============================================================================

title Portable Ollama + OpenClaw

echo.
echo ============================================================
echo        STARTING PORTABLE OLLAMA + OPENCLAW
echo ============================================================
echo.

:: ============================================================================
:: INITIALIZE ISOLATED ENVIRONMENT
:: ============================================================================

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

:: ============================================================================
:: LOCATE OPENCLAW
:: ============================================================================

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
echo OpenClaw Home:     %OPENCLAW_HOME%
echo OpenClaw Config:   %OPENCLAW_CONFIG_PATH%
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
    echo Check the Portable Ollama process.
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
:: VERIFY OLLAMA API
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
:: DISPLAY AVAILABLE OLLAMA MODELS
:: ============================================================================

echo.
echo ============================================================
echo             AVAILABLE OLLAMA MODELS
echo ============================================================
echo.

"%OLLAMA_EXE%" list

if errorlevel 1 (
    echo.
    echo ERROR: Unable to retrieve Ollama model list.
    echo.
    pause
    exit /b 1
)

:: ============================================================================
:: START OPENCLAW GATEWAY
:: ============================================================================
::
:: The Gateway is deliberately run directly.
::
:: DO NOT:
::
::   - install the OpenClaw Windows service
::   - use a separately installed Gateway
::   - use "ollama signin"
::
:: This Gateway inherits the isolated environment established above.
::
:: ============================================================================

echo.
echo ============================================================
echo             STARTING OPENCLAW GATEWAY
echo ============================================================
echo.

echo OpenClaw:
echo   %OPENCLAW_CMD%
echo.
echo Port:
echo   18789
echo.
echo Config:
echo   %OPENCLAW_CONFIG_PATH%
echo.
echo.

:: ============================================================================
:: CHECK WHETHER PORT 18789 IS ALREADY IN USE
:: ============================================================================
::
:: If another process already owns the port, do not blindly launch a second
:: Gateway. This prevents duplicate Gateway instances.
::
:: ============================================================================

echo Checking OpenClaw Gateway port...

curl.exe --silent --show-error --fail ^
    "http://%_HOST%:18789/" >nul 2>&1

if "%ERRORLEVEL%"=="0" (
    echo.
    echo OpenClaw Gateway is already responding on:
    echo   http://%_HOST%:18789
    echo.
    goto OPENCLAW_READY
)

echo No responding Gateway detected.
echo Starting isolated OpenClaw Gateway...
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
:: VERIFY OPENCLAW GATEWAY STATUS
:: ============================================================================
::
:: This is informational. The HTTP readiness test above is the actual
:: condition used to continue.
::
:: ============================================================================

echo.
echo ============================================================
echo             OPENCLAW GATEWAY STATUS
echo ============================================================
echo.

call "%OPENCLAW_CMD%" gateway status

echo.

:: ============================================================================
:: OPEN DASHBOARD
:: ============================================================================
::
:: "openclaw dashboard" uses the current Gateway authentication/configuration
:: and opens the Control UI.
::
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
    echo The Gateway itself is running at:
    echo   http://%_HOST%:18789
    echo.
    pause
    exit /b %OPENCLAW_EXIT%
)

:: ============================================================================
:: COMPLETE
:: ============================================================================

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
echo Dashboard:
echo   OpenClaw Control UI has been opened.
echo.
echo Ollama and OpenClaw Gateway remain running.
echo.
echo ============================================================
echo.

endlocal
exit /b 0