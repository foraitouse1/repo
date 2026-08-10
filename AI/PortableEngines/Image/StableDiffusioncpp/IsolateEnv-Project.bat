@echo off

:: ============================================================
:: IsolateEnv-Project.bat
:: ============================================================

call "%~dp0IsolateEnv.bat"

if not defined SCRIPT_DIR (
    echo ERROR: IsolateEnv.bat failed
    exit /b 1
)

:: ============================================================
:: Fundamental Project Definitions
:: ============================================================

SET "_HOST=127.0.0.1"

SET "_LOG_DIR=%SCRIPT_DIR%logs"
if not exist "%_LOG_DIR%" mkdir "%_LOG_DIR%"

goto DATA


::Items are added in alpha sort order by IsolateEnv-Project-Add.bat


:DATA

::added by 'DownloadInstall-CACert.bat'
set "SSL_CERT_FILE=%COMMONPROGRAMFILES%\cacert.pem"
ECHO SSL_CERT_FILE=%SSL_CERT_FILE%

::added by 'Download-Llamacpp-Model.bat'
set "_MODEL_DIR=%SCRIPT_DIR%Models"
ECHO _MODEL_DIR=%_MODEL_DIR%

::added by 'DownloadInstall-Llamacpp.bat'
set "_LLAMA_BACKEND=vulkan"
ECHO _LLAMA_BACKEND=%_LLAMA_BACKEND%

::added by 'DownloadInstall-Llamacpp.bat'
set "_LLAMA_DIR=%SCRIPT_DIR%llama.cpp\%_LLAMA_BACKEND%"
ECHO _LLAMA_DIR=%_LLAMA_DIR%

::added by 'DownloadInstall-Llamacpp.bat'
set "LLAMA_CACHE=%SCRIPT_DIR%Models\llamacache"
ECHO LLAMA_CACHE=%LLAMA_CACHE%

::added by 'DownloadInstall-Llamacpp.bat'
set "HF_HOME=%SCRIPT_DIR%Models\hfcache"
ECHO HF_HOME=%HF_HOME%

::added by 'Run-Llamacpp.bat'
set "_PORT=11434"
ECHO _PORT=%_PORT%

