:: Run-Engine-Ollama - OpenClaw - Get tokenized dashboard URL.bat
::
:: Starts the portable Ollama server, waits until the API is ready,
:: then launches the portable OpenClaw command.
::
:: OpenClaw is installed under:
::
::     %_NODEJS_DIR%\node_modules\openclaw
::
:: The Windows command wrapper is:
::
::     %_NODEJS_DIR%\openclaw.cmd
::

@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ============================================================
:: Portable Ollama + OpenClaw
:: ============================================================

echo ============================================================
echo        STARTING PORTABLE OLLAMA + OPENCLAW
echo ============================================================
echo.

:: ============================================================
:: Initialize isolated environment
:: ============================================================

call "%~dp0IsolateEnv-Initialize.bat"

if errorlevel 1 (
    echo.
    echo ERROR: IsolateEnv initialization failed.
    pause
    exit /b 1
)

:: ============================================================
:: Ollama configuration
:: ============================================================

set "_OLLAMA_PORT=11434"

set "OLLAMA_HOST=127.0.0.1:%_OLLAMA_PORT%"

set "OLLAMA_DEBUG=0"
set "OLLAMA_KEEP_ALIVE=-1"
set "OLLAMA_NUM_PARALLEL=1"
set "OLLAMA_MAX_LOADED_MODELS=1"
set "OLLAMA_MAX_QUEUE=512"
set "OLLAMA_FLASH_ATTENTION="

:: ============================================================
:: Ollama paths
:: ============================================================

if not defined _ENGINE_DIR (
    echo ERROR: _ENGINE_DIR is not defined.
    pause
    exit /b 1
)

if not defined OLLAMA_MODELS (
    echo ERROR: OLLAMA_MODELS is not defined.
    pause
    exit /b 1
)

set "_OLLAMA_EXE=%_ENGINE_DIR%\ollama.exe"

if not exist "%_OLLAMA_EXE%" (
    echo.
    echo ERROR: ollama.exe was not found:
    echo %_OLLAMA_EXE%
    pause
    exit /b 1
)

:: ============================================================
:: OpenClaw paths
:: ============================================================

if not defined _NODEJS_DIR (
    echo.
    echo ERROR: _NODEJS_DIR is not defined.
    pause
    exit /b 1
)

set "_OPENCLAW_DIR=%_NODEJS_DIR%\node_modules\openclaw"
set "_OPENCLAW_CMD=%_NODEJS_DIR%\openclaw.cmd"

if not exist "%_OPENCLAW_DIR%" (
    echo.
    echo ERROR: OpenClaw installation was not found:
    echo %_OPENCLAW_DIR%
    pause
    exit /b 1
)

if not exist "%_OPENCLAW_CMD%" (
    echo.
    echo ERROR: OpenClaw command wrapper was not found:
    echo %_OPENCLAW_CMD%
    pause
    exit /b 1
)

:: ============================================================
:: Display configuration
:: ============================================================

echo ============================================================
echo        EXPORTING OLLAMA CONFIGURATION
echo ============================================================
echo.
echo Ollama executable:    %_OLLAMA_EXE%
echo Ollama host:          %OLLAMA_HOST%
echo Ollama models:        %OLLAMA_MODELS%
echo Ollama keep alive:    %OLLAMA_KEEP_ALIVE%
echo Ollama parallel:      %OLLAMA_NUM_PARALLEL%
echo Ollama max loaded:    %OLLAMA_MAX_LOADED_MODELS%
echo Ollama max queue:     %OLLAMA_MAX_QUEUE%
echo Ollama Flash Attention: %OLLAMA_FLASH_ATTENTION%
echo.
echo OpenClaw directory:   %_OPENCLAW_DIR%
echo OpenClaw command:     %_OPENCLAW_CMD%
echo.

:: ============================================================
:: Start Ollama server
:: ============================================================

echo ============================================================
echo        STARTING OLLAMA SERVER
echo ============================================================
echo.

start "Portable Ollama Server" /B "%_OLLAMA_EXE%" serve

:: ============================================================
:: Wait for Ollama API
:: ============================================================

echo Waiting for Ollama...

set "_OLLAMA_READY=0"

for /L %%N in (1,1,60) do (

    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
        "$ErrorActionPreference='SilentlyContinue'; try { $r=Invoke-WebRequest -Uri 'http://%OLLAMA_HOST%/' -UseBasicParsing -TimeoutSec 1; if ($r.StatusCode -eq 200) { exit 0 } } catch {}; exit 1" >nul 2>&1

    if not errorlevel 1 (
        set "_OLLAMA_READY=1"
        goto OllamaReady
    )

    timeout /t 1 /nobreak >nul
)

:OllamaReady

if "%_OLLAMA_READY%"=="0" (
    echo.
    echo ERROR: Ollama did not become ready within 60 seconds.
    echo.
    echo Expected API:
    echo http://%OLLAMA_HOST%
    echo.
    pause
    exit /b 1
)

echo Ollama is ready.
echo.

:: ============================================================
:: Verify OpenClaw command
:: ============================================================

echo ============================================================
echo        VERIFYING OPENCLAW
echo ============================================================
echo.

echo OpenClaw directory:
echo %_OPENCLAW_DIR%
echo.

echo OpenClaw command:
echo %_OPENCLAW_CMD%
echo.

if not exist "%_OPENCLAW_CMD%" (
    echo ERROR: OpenClaw command wrapper disappeared.
    pause
    exit /b 1
)

echo OpenClaw command found.
echo.

:: ============================================================
:: Launch OpenClaw
:: ============================================================

echo ============================================================
echo        STARTING OPENCLAW
echo ============================================================
echo.

echo Launching:
echo %_OPENCLAW_CMD%
echo.

call "%_OPENCLAW_CMD%" dashboard

set "_OPENCLAW_EXIT=%ERRORLEVEL%"

:: ============================================================
:: Finished
:: ============================================================

echo.
echo ============================================================
echo        OPENCLAW STOPPED
echo ============================================================
echo.
echo Exit code: %_OPENCLAW_EXIT%
echo.

pause

endlocal
exit /b %_OPENCLAW_EXIT%
