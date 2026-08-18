@echo off
setlocal EnableExtensions DisableDelayedExpansion

if /i "%~1"=="--set-config" goto SET_CONFIG
if /i "%~1"=="--set-json" goto SET_JSON

call "%~dp0IsolateEnv-Initialize.bat"
if errorlevel 1 exit /b 1

if not defined OPENCLAW_HOME (
    echo ERROR: OPENCLAW_HOME is not defined.
    exit /b 1
)

if not defined OPENCLAW_CONFIG_PATH (
    echo ERROR: OPENCLAW_CONFIG_PATH is not defined.
    exit /b 1
)

if not defined _PYTHON_DIR (
    echo ERROR: _PYTHON_DIR is not defined.
    exit /b 1
)

if not defined _GIT_DIR (
    echo ERROR: _GIT_DIR is not defined.
    exit /b 1
)

set "_OPENCLAW_CMD=%OPENCLAW_HOME%\openclaw.cmd"
set "_OPENCLAW_WORKSPACE=%OPENCLAW_HOME%\workspace"

set "OLLAMA_MODEL=qwen3-coder-next:q8_0"
set "OLLAMA_EMBED_MODEL=nomic-embed-text"
set "OLLAMA_EMBED_DIMENSIONS=768"
set "OLLAMA_API_KEY=ollama-local"

if not exist "%_OPENCLAW_CMD%" (
    echo ERROR: OpenClaw executable not found:
    echo %_OPENCLAW_CMD%
    exit /b 1
)

if not exist "%_PYTHON_DIR%\python.exe" (
    echo ERROR: Portable Python not found:
    echo %_PYTHON_DIR%\python.exe
    exit /b 1
)

if not exist "%_GIT_DIR%\cmd\git.exe" (
    echo ERROR: Portable Git not found:
    echo %_GIT_DIR%\cmd\git.exe
    exit /b 1
)

if not exist "%_OPENCLAW_WORKSPACE%" mkdir "%_OPENCLAW_WORKSPACE%"

if not exist "%_OPENCLAW_WORKSPACE%" (
    echo ERROR: Unable to create workspace:
    echo %_OPENCLAW_WORKSPACE%
    exit /b 1
)

endlocal & (
    set "_OPENCLAW_CMD=%_OPENCLAW_CMD%"
    set "_OPENCLAW_WORKSPACE=%_OPENCLAW_WORKSPACE%"
    set "OLLAMA_MODEL=%OLLAMA_MODEL%"
    set "OLLAMA_EMBED_MODEL=%OLLAMA_EMBED_MODEL%"
    set "OLLAMA_EMBED_DIMENSIONS=%OLLAMA_EMBED_DIMENSIONS%"
    set "OLLAMA_API_KEY=%OLLAMA_API_KEY%"
)
exit /b 0

:SET_CONFIG
set "_CFG_PATH=%~2"
set "_CFG_VALUE=%~3"
set "_CFG_TYPE=%~4"
set "_CFG_CURRENT="

for /f "delims=" %%A in ('"%_OPENCLAW_CMD%" config get %_CFG_PATH% 2^>nul') do (
    if not defined _CFG_CURRENT set "_CFG_CURRENT=%%A"
)

if /i "%_CFG_TYPE%"=="bool" (
    set "_CFG_DESIRED=%_CFG_VALUE%"
) else if /i "%_CFG_TYPE%"=="number" (
    set "_CFG_DESIRED=%_CFG_VALUE%"
) else (
    set "_CFG_DESIRED=%_CFG_VALUE%"
)

if defined _CFG_CURRENT if "%_CFG_CURRENT%"=="%_CFG_DESIRED%" (
    echo [SKIP] %_CFG_PATH%
    echo        already = %_CFG_CURRENT%
    endlocal
    exit /b 0
)

if /i "%_CFG_TYPE%"=="bool" (
    "%_OPENCLAW_CMD%" config set %_CFG_PATH% %_CFG_VALUE%
) else if /i "%_CFG_TYPE%"=="number" (
    "%_OPENCLAW_CMD%" config set %_CFG_PATH% %_CFG_VALUE%
) else (
    "%_OPENCLAW_CMD%" config set %_CFG_PATH% "%_CFG_VALUE%"
)

if errorlevel 1 (
    echo ERROR: Failed setting %_CFG_PATH%.
    endlocal
    exit /b 1
)

echo [SET] %_CFG_PATH%
echo       = %_CFG_VALUE%

endlocal
exit /b 0

:SET_JSON
set "_CFG_PATH=%~2"
set "_CFG_JSON=%~3"
set "_CFG_CURRENT="

for /f "delims=" %%A in ('"%_OPENCLAW_CMD%" config get %_CFG_PATH% --json 2^>nul') do (
    if not defined _CFG_CURRENT set "_CFG_CURRENT=%%A"
)

if "%_CFG_CURRENT%"=="%_CFG_JSON%" (
    echo [SKIP] %_CFG_PATH%
    echo        already = %_CFG_CURRENT%
    endlocal
    exit /b 0
)

"%_OPENCLAW_CMD%" config set %_CFG_PATH% "%_CFG_JSON%" --strict-json

if errorlevel 1 (
    echo ERROR: Failed setting %_CFG_PATH%.
    endlocal
    exit /b 1
)

echo [SET] %_CFG_PATH%
echo       = %_CFG_JSON%

endlocal
exit /b 0