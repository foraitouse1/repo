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

::added by 'DownloadInstall-StableDiffusioncpp.bat'
set "_ENGINE_BACKEND=vulkan"
ECHO _ENGINE_BACKEND=%_ENGINE_BACKEND%

::added by 'DownloadInstall-StableDiffusioncpp.bat'
set "_ENGINE_DIR=%SCRIPT_DIR%Engine\%_ENGINE_BACKEND%"
ECHO _ENGINE_DIR=%_ENGINE_DIR%

::added by 'DownloadInstall-StableDiffusioncpp.bat'
set "LLAMA_CACHE=%SCRIPT_DIR%Models\llamacache"
ECHO LLAMA_CACHE=%LLAMA_CACHE%

::added by 'DownloadInstall-StableDiffusioncpp.bat'
set "HF_HOME=%SCRIPT_DIR%Models\hfcache"
ECHO HF_HOME=%HF_HOME%

::added by 'Run-Engine.bat'
set "_SD_PORT=7860"
ECHO _SD_PORT=%_SD_PORT%

