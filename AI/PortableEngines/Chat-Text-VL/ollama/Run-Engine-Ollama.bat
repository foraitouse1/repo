@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Portable Ollama Engine Launcher
:: ====================================================

call "%~dp0IsolateEnv-Initialize.bat"

if not defined _ENGINE_DIR (
    echo ERROR: _ENGINE_DIR is not defined by IsolateEnv-Project.bat
    pause
    exit /b 1
)

if not defined _HOST (
    echo ERROR: _HOST is not defined by IsolateEnv-Project.bat
    pause
    exit /b 1
)


:: ====================================================
:: Ollama Configuration
:: ====================================================

:: Ollama server host/port.
:: _HOST is supplied by IsolateEnv-Project.bat.
set "_OLLAMA_PORT=11434"

call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "_OLLAMA_PORT=11434"
if errorlevel 1 (
    echo ERROR: Failed adding _OLLAMA_PORT to IsolateEnv-Project.bat
    pause
    exit /b 1
)

set "_OLLAMA_EXE=%_ENGINE_DIR%\ollama.exe"

if not exist "%_OLLAMA_EXE%" (
    echo ERROR: ollama.exe was not found:
    echo %_OLLAMA_EXE%
    pause
    exit /b 1
)

:: Enables Ollama debug logging.
:: 0 = normal logging.
:: 1 = verbose diagnostic logging.
:: Log files should be under:
:: Cdrive\User\AppData\Local\Ollama\
set "OLLAMA_DEBUG=0"

:: How long a model remains loaded in memory after becoming idle.
:: Examples: 5m, 30m, 1h, 0 = unload immediately, -1 = indefinite.
set "OLLAMA_KEEP_ALIVE=-1"

:: Maximum number of parallel model requests Ollama will process.
set "OLLAMA_NUM_PARALLEL=1"

:: Maximum number of models Ollama may keep loaded simultaneously.
set "OLLAMA_MAX_LOADED_MODELS=1"

:: Maximum number of requests allowed to wait in Ollama's queue.
set "OLLAMA_MAX_QUEUE=512"

:: Enables Flash Attention for supported models/hardware.
:: Flash Attention uses a more memory-efficient attention implementation
:: that can reduce GPU memory usage and potentially improve performance.
:: Blank = let Ollama decide.
:: 0     = explicitly disable.
:: 1     = explicitly enable.
set "OLLAMA_FLASH_ATTENTION="


:: ====================================================
:: Start
:: ====================================================

set "OLLAMA_HOST=%_HOST%:%_OLLAMA_PORT%"

:: ====================================================
:: Display Configuration
:: ====================================================

echo.
echo Ollama executable: %_OLLAMA_EXE%
echo Host:              %OLLAMA_HOST%
echo Models:            %OLLAMA_MODELS%
echo Keep alive:        %OLLAMA_KEEP_ALIVE%
echo Parallel models:   %OLLAMA_NUM_PARALLEL%
echo Max loaded models: %OLLAMA_MAX_LOADED_MODELS%
echo Max queue:         %OLLAMA_MAX_QUEUE%
echo Flash Attention:   %OLLAMA_FLASH_ATTENTION%
echo.

echo ====================================================
echo       LAUNCHING OLLAMA
echo ====================================================
echo.
echo Ollama API:
echo http://%OLLAMA_HOST%
echo.
echo Press Ctrl+C to stop Ollama.
echo.


:: ====================================================
:: Launch Ollama Server
:: ====================================================

"%_OLLAMA_EXE%" serve

set "_OLLAMA_EXIT=%ERRORLEVEL%"


:: ====================================================
:: Shutdown
:: ====================================================

echo.
echo ====================================================
echo       OLLAMA STOPPED
echo ====================================================
echo.
echo Exit code: %_OLLAMA_EXIT%
echo.

pause

endlocal
exit /b %_OLLAMA_EXIT%
